//
//  OpenDirectoryService.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/21/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "OpenDirectoryService.h"
#import <AHServers/AHServers.h>
#import "ODUProgress.h"
#import "ODUError.h"
#import "NSString+uuidFromString.h"
#import <syslog.h>

@interface OpenDirectoryService()<AHDirectoryDelegate>{
}
@property (strong,nonatomic)  AHDirectoryManager* manager;
@end

@implementation OpenDirectoryService{
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
        shared.manager = [AHDirectoryManager sharedManager];
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
    NSString *msg=[NSString stringWithFormat:@"Added user %@ progress %f",record,progress];
    [[self.xpcConnection remoteObjectProxy] setProgress:progress withMessage:msg];
}

-(void)didAddUser:(NSString *)user toGroup:(NSString *)group progress:(double)progress{
    [[self.xpcConnection remoteObjectProxy] setProgressMsg:[NSString stringWithFormat:@"Updating %@ membership, adding %@",group,user]];
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

    if(userError && groupError)
        error = [ODUError errorWithCode:ODUMCantAddUserToServerOrGroup ];
    else if(groupError)error = groupError;
    else if(userError)error = userError;
    
    reply(error);
}

-(void)addListOfUsers:(ODUserList*)users withGroups:(NSArray*)groups withReply:(void (^)(NSError *error))reply{
    [_manager setDelegate:self];
    [_manager addListOfUsers:users reply:^(NSError *error) {
        if(error){
            NSLog(@"List add error: %@",error.localizedDescription);
            if([error.localizedDescription isEqualToString:@"Import Canceled"]){
                reply(error);
                return;
            }
        }
        
        for(NSDictionary* group in groups){
            NSString *groupName = group[@"group"];
            NSArray  *users = group[@"users"];
            [[AHDirectoryManager sharedManager] addUsers:users toGroup:groupName error:&error];
        }
        reply(error);
    }];
}

-(void)cancelImportStatus:(void (^)(BOOL canceled))reply{
    _manager = [AHDirectoryManager sharedManager];
    [_manager cancelUserImport];
    reply(YES);
}

-(void)resetUserPassword:(ODUser*)user withReply:(void (^)(NSError *error))reply{
    NSError *error;
    [_manager resetPassword:nil toPassword:user.passWord user:user.userName error:&error];
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
-(void)checkServerStatus:(ODServer*)server withReply:(void (^)(OSStatus connected))reply{
    // init the query set here since whenever we change the server,the old querys will no longer be accessible
 
    OSStatus status = kAHNodeNotSet;
    NSError* error;
    _manager.authenticated = NO;

    _manager.directoryServer = server.directoryServer;
    _manager.directoryDomain = kAHDefaultDomain;
    
    _manager.diradmin = server.diradminName;
    _manager.diradminPassword = server.diradminPass;
    status = [_manager authenticate:&error];
    
    if(_manager.authenticated){
        reply(status);
        return;
    }else{
        _manager.directoryDomain = kAHProxyDirectoryServer;
        reply([_manager authenticate:&error]);
    }
}



@end
