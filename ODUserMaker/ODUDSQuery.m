//
//  ODUDSQuery.m
//  ODUserMaker
//
//  Created by Eldon on 11/12/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUDSQuery.h"
#import "OpenDirectoryService.h"
#import "FileService.h"

#import "ODCommonHeaders.h"
#import "ODUController.h"

@implementation ODUDSQuery

-(id)initWithDelegate:(id)delegate{
    self = [super init];
    if(self){
        _delegate = delegate;
    }
    return self;
}

-(void)getDSGroupList{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = _delegate;
    [connection resume];
    [[connection remoteObjectProxy] getGroupListFromServer:^(NSArray *gArray, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(!error){
                [_delegate didGetDSGroupList:gArray];
            }
        }];
        [connection invalidate];
    }];
}

-(void)getDSUserList{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = _delegate ;
    [connection resume];
    [[connection remoteObjectProxy] getUserListFromServer:^(NSArray *uArray, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(!error){
                NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending: YES];
                NSArray* userList = [uArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
                [_delegate didGetDSUserList:userList];
            }
        }];
        [connection invalidate];
    }];
}

-(void)getDSUserPresets{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = _delegate;
    [connection resume];
    [[connection remoteObjectProxy] getUserPresets:^(NSArray *pArray, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(!error){
                [_delegate didGetDSUserPresets:pArray];
            }
        }];
        [connection invalidate];
    }];
}

-(void)getSettingsForPreset{
    NSString* presetName = [_delegate nameOfPreset];
    if(!presetName){
        return;
    }
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = _delegate;
    [connection resume];
    [[connection remoteObjectProxy] getSettingsForPreset:presetName withReply:^(NSDictionary *settings, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(!error){
                [_delegate didGetSettingsForPreset:settings];
            }
        }];
        [connection invalidate];
    }];

}






+(void)addUser:(User*)user toGroups:userGroups sender:(ODUController*)sender{
    NSString* progress = [NSString stringWithFormat:@"adding %@ to %@...",
                          user.userName, sender.serverNameTF.stringValue];
    
    [sender startProgressPanelWithMessage:progress indeterminate:YES];
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = sender;
    [connection resume];
    [[connection remoteObjectProxy] addSingleUser:user andGroups:userGroups withReply:^(NSError *error){
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [sender stopProgressPanel];
            if(error){
                NSLog(@"Error: %@",[error localizedDescription]);
                [ODUAlerts showErrorAlert:error];
            }else{
                sender.statusUpdateUserTF.stringValue = [NSString stringWithFormat:@"Added/Updated %@",user.userName];
            }
        }];
        [connection invalidate];
    }];

}

+(void)addUserList:(User *)user withGroups:(NSArray *)groups sender:(ODUController *)sender{
    NSString* progress = @"Adding user list...";
    [sender startProgressPanelWithMessage:progress indeterminate:YES];
    NSXPCConnection* fileServiceConnection = [[NSXPCConnection alloc] initWithServiceName:kFileServiceName];
    fileServiceConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(FileService)];
    fileServiceConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    fileServiceConnection.exportedObject = sender;
    [fileServiceConnection resume];
    [[fileServiceConnection remoteObjectProxy] makeUserArray:user andGroupList:groups withReply:^(NSArray* groupList,NSArray* userlist, NSError* error){
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [fileServiceConnection invalidate];
            if(error){
                [ODUAlerts showErrorAlert:error];
                [sender stopProgressPanel];
            }else if (user.exportFile){
                [sender stopProgressPanel];
                return;
            }else{
                [sender.progressIndicator setIndeterminate:NO];
                [sender.progressIndicator setUsesThreadedAnimation:YES];
                
                user.userList = userlist;
                user.groupList = groupList;
                
                NSXPCConnection* directoryServiceConnection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
                directoryServiceConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
                
                directoryServiceConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
                directoryServiceConnection.exportedObject = sender;
                
                [directoryServiceConnection resume];
                [[directoryServiceConnection remoteObjectProxy] addListOfUsers:user withReply:^(NSError *error) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [sender stopProgressPanel];
                        if(error){
                            NSLog(@"Error: %@",[error localizedDescription]);
                            [ODUAlerts showErrorAlert:error];
                        }
                    }];
                    DLog(@"Invalidated DS Connection");
                    [directoryServiceConnection invalidate];
                }];
            }
        }];
    }];
}



+(void)cancelUserImport:(ODUController*)sender{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    [connection resume];
    [[connection remoteObjectProxy] cancelImportStatus:^(OSStatus connected) {
        [sender stopProgressPanel];
        [connection invalidate];
    }];
}


+(void)resetPassword:(User *)user sender:(ODUController *)sender{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = sender;
    [connection resume];
    [[connection remoteObjectProxy] resetUserPassword:user withReply:^(NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [sender stopProgressPanel];
            if(error){
                NSLog(@"Error: %@",[error localizedDescription]);
                [ODUAlerts showErrorAlert:error];
            }else{
                sender.statusUpdateUserTF.textColor = [NSColor redColor];
                sender.statusUpdateUserTF.stringValue = [NSString stringWithFormat:@"Password reset for %@",user.userName];
            }
        }];
        [connection invalidate];
    }];

}
@end
