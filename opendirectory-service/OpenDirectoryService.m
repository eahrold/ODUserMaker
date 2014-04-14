//
//  OpenDirectoryService.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/21/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "OpenDirectoryService.h"
#import "ODManager.h"
#import "ODUProgress.h"
#import "ODUError.h"
#import <syslog.h>

@interface OpenDirectoryService()<ODManagerDelegate>{
}
@property (strong,nonatomic)  ODManager* manager;
@end

@implementation OpenDirectoryService{
    BOOL _cancelOperation;
}
#pragma mark - Sinleton and Listener Delegate
//---------------------------------
//  Singleton and ListenerDelegate
//---------------------------------

+ (OpenDirectoryService*)sharedDirectoryServer {
    static dispatch_once_t onceToken;
    static OpenDirectoryService* shared;
    dispatch_once(&onceToken, ^{
        shared = [OpenDirectoryService new];
        shared.manager = [ODManager sharedManager];
    });
    return shared;
}

- (BOOL)listener:(NSXPCListener*)listener shouldAcceptNewConnection:(NSXPCConnection*)newConnection {
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    newConnection.exportedObject = self;
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    self.xpcConnection = newConnection;
    [newConnection resume];
    return YES;
}

#pragma mark - AHDirectoryDelegate
-(void)didRecieveQueryUpdate:(NSDictionary *)record{
    [[self.xpcConnection remoteObjectProxy] gotUserRecord:record[@"name"]];
}

-(void)didRecieveStatusUpdate:(OSStatus)status{
    NSLog(@"status %d",status);
}

-(void)didAddRecord:(NSString *)record progress:(double)progress{
    NSString *msg=[NSString stringWithFormat:@"Progress %d, Adding user %@ ",(int)ceil(progress),record];
    [[self.xpcConnection remoteObjectProxy] setProgress:progress withMessage:msg];
}

-(void)didAddUser:(NSString *)user toGroup:(NSString *)group progress:(double)progress{
    [[self.xpcConnection remoteObjectProxy] setProgressMsg:[NSString stringWithFormat:@"Updating %@ membership, adding %@",group,user]];
}

-(void)didRemoveUser:(NSString *)user fromGroup:(NSString *)group progress:(double)progress{
    
}

-(void)didChangePasswordForUser:(NSString*)user{
    NSString* msg = [NSString stringWithFormat:@"Resetting password for %@",user];
    [[self.xpcConnection remoteObjectProxy] setProgressMsg:msg];
}

#pragma mark - NSXPC ODUser Actions
//------------------------------------------------------------
//  NSXPC ODUser Change Methods
//------------------------------------------------------------

-(void)addSingleUser:(ODUser*)user withGroups:(NSArray*)groups withReply:(void (^)(NSError *error))reply{
    _manager.delegate = self;
    NSError *error;
    NSError* userError;
    NSError* groupError;

    [_manager addUser:user error:&userError];
    
    for(NSString *g in groups){
        [_manager addUser:user.userName toGroup:g error:&groupError];
    }
    
    reply(error);
}

-(void)addListOfUsers:(ODRecordList*)users withGroups:(NSArray*)groups withReply:(void (^)(NSError *error))reply{
    [[ODManager sharedManager] setDelegate:self];
    [[ODManager sharedManager] addListOfUsers:users reply:^(NSError *error) {
        if(error){
            NSLog(@"List add error: %@",error.localizedDescription);
            if([error.localizedDescription isEqualToString:@"Import Canceled"]){
                reply(error);
                return;
            }
        }
        for(NSDictionary* group in groups){
            NSString* msg = [NSString stringWithFormat:@"adding users to group %@",group[@"group"]];
            [[self.xpcConnection remoteObjectProxy] setProgressMsg:msg];

            NSString *groupName = group[@"group"];
            NSArray  *users = group[@"users"];
            [[ODManager sharedManager] addUsers:users toGroup:groupName error:&error];
        }
        [[ODManager sharedManager] setDelegate:nil];
        reply(error);
    }];
}

-(void)cancelImportStatus:(void (^)(BOOL canceled))reply{
    _manager = [ODManager sharedManager];
    [_manager cancelUserImport];
    _cancelOperation = YES;
    reply(YES);
}

-(void)resetUserPassword:(ODUser*)user withReply:(void (^)(NSError *error))reply{
    NSError *error;
    [_manager resetPassword:nil toPassword:user.passWord user:user.userName error:&error];
    reply(error);
}

-(void)resetPasswordsForUsers:(ODRecordList *)recordList reply:(void (^)(NSError *))reply{
    NSOperationQueue *bkQueue = [[NSOperationQueue alloc]init];
    [bkQueue addOperationWithBlock:^{
        NSError *error;
        ODManager *manager = [ODManager sharedManager];
        _cancelOperation = NO;
        
        NSMutableArray *passResetErrors = [[NSMutableArray alloc] initWithCapacity:recordList.users.count];
        int errorCount = 0;
        while(!_cancelOperation){
            for(ODUser* user in recordList.users){
                
                if(_cancelOperation)break;
                
                [manager resetPassword:nil toPassword:user.passWord user:user.userName error:&error];
                NSString* msg = [NSString stringWithFormat:@"Resetting password for %@",user];

                [[NSOperationQueue mainQueue]addOperationWithBlock:^{
                    [[self.xpcConnection remoteObjectProxy] setProgressMsg:msg];
                }];
                
                if(error){
                    [passResetErrors addObject:user.userName];
                    errorCount++;
                    error = nil;
                }
            }
            break;
        }
        if(errorCount > 0){
            NSLog(@"Error Changing Passwords for %d users.  These Users: %@",errorCount,passResetErrors);
            error = [ODUError errorWithCode:ODUMProblemResettingUsersPasswords];
        }
        reply(error);
    }];
}

-(void)deleteUser:(NSString *)user reply:(void (^)(NSError *))reply{
    NSError *error;
    [_manager removeUser:user error:&error];
    reply(error);
}

-(void)addUser:(NSString *)user toGroup:(NSString *)group reply:(void (^)(NSError *))reply{
    NSError *error;
    [_manager addUser:user toGroup:group error:&error];
    reply(error);
}

-(void)removeUser:(NSString *)user fromGroup:(NSString *)group reply:(void (^)(NSError *))reply{
    NSError *error;
    [_manager removeUser:user fromGroup:group error:&error];
    reply(error);
}

#pragma mark - NSXPC Record Request
//------------------------------------------------------------
//  NSXPC Query Methods
//------------------------------------------------------------

-(void)getUserListAsync:(void (^)(NSError *))reply{
    [_manager userListWithDelegate:self];
}

-(void)getUserListFromServer:(void (^)(NSArray *userList,NSError *error))reply{
    [_manager userList:^(NSArray *array) {
        reply(array,nil);
    }];
}

-(void)getGroupListFromServer:(void (^)(NSArray *groupList,NSError *error))reply{
    [_manager groupList:^(NSArray *array) {
        reply(array,nil);
    }];
}

-(void)getPresetsListFromServer:(void (^)(NSArray *presetList,NSError *error))reply{
    [_manager presetList:^(NSArray *presets) {
        reply(presets,nil);
    }];
}

-(void)getSettingsForPreset:(NSString*)preset
                  withReply:(void (^)(ODPreset *preset,NSError *error))reply{
    ODPreset *pst= [_manager settingsForPreset:preset];
    reply(pst,nil);
}

//--------------------------------------------------------------
//  Private Methods for Editing ODUsers and Groups
//--------------------------------------------------------------
#pragma mark  - Add / Create Internal
-(BOOL)addGroups:(NSArray*)groups error:(NSError**)error{
    NSArray* users;
    NSString* groupName;
    
    for(NSDictionary* group in groups){
        groupName = group[@"group"];
        users = group[@"users"];
        [_manager addUsers:users toGroup:groupName error:error];
    }

    return YES;
}


#pragma mark - Node Status Check
//---------------------------------------------
//  Open Directory Node Status Checks
//---------------------------------------------
-(void)checkServerStatus:(ODServer*)server withReply:(void (^)(OSStatus connected,NSString *))reply{
    // init the query set here since whenever we change the server,the old querys will no longer be accessible
    NSError* error;
    OSStatus status = kODMNodeNotSet;
    _manager.delegate = self;
    _manager.directoryServer = server.directoryServer;
    _manager.directoryDomain = kODMDefaultDomain;
    _manager.diradmin = server.diradminName;
    _manager.diradminPassword = server.diradminPass;
    status = [_manager authenticate:&error];
    
    if(_manager.authenticated){
        reply(status,nodeStatusDescription(status));
        return;
    }else{
        _manager.directoryDomain = kODMProxyDirectoryServer;
        status = [_manager authenticate:&error];
        
        reply(status,nodeStatusDescription(status));
    }
}



@end
