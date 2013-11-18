//
//  ODUDSQuery.m
//  ODUserMaker
//
//  Created by Eldon on 11/12/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUDSQuery.h"
#import "ODUserError.h"
#import "SecuredObjects.h"
#import "OpenDirectoryService.h"
#import "FileService.h"
#import "ODUStatus.h"
#import "ODUController.h"
#import "ODUAlerts.h"

@implementation ODUDSQuery

+(BOOL)getAuthenticatedDirectoryNode:(Server*)server error:(NSError**)error{
    NSError* _error;
    /* don't bother checking untill everything is in place */
    
    if([server.serverName isEqualToString:@""] ||
       [server.diradminName isEqualToString:@""] ||
       [server.diradminPass isEqualToString:@""]){
        _error = [ODUserError errorWithCode:ODUMFieldsMissing];
        if(error)*error = _error;
        return NO;
    }
  
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    //connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    //connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] checkServerStatus:server withReply:^(OSStatus status)  {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [ODUStatus sharedStatus].serverStatus = status;
            }
        ];
        [connection invalidate];
    }];
    return YES;
}

+(void)getDSUserList{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
//    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
//    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] getUserListFromServer:^(NSArray *uArray, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(!error){
                NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending: YES];
                NSArray* userList = [uArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
                [[ODUStatus sharedStatus] setUserList:userList];
            }
        }];
        [connection invalidate];
    }];
}

+(void)getDSGroupList{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    //connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    //connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] getGroupListFromServer:^(NSArray *gArray, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(!error){
                [[ODUStatus sharedStatus]setGroupList:gArray];
            }
        }];
        [connection invalidate];
    }];
}

+(void)getDSUserPresets{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    //connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    //connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] getUserPresets:^(NSArray *pArray, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(!error){
                [[ODUStatus sharedStatus]setPresetList:pArray];
            }
        }];
        [connection invalidate];
    }];

}

+(void)getSettingsForPreset:(NSString*)preset sender:(ODUController*)sender{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = sender;
    [connection resume];
    [[connection remoteObjectProxy] getSettingsForPreset:preset withReply:^(NSDictionary *settings, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(!error){
                sender.sharePoint.stringValue = [settings valueForKey:@"sharePoint"];
                sender.sharePath.stringValue = [settings valueForKey:@"sharePath"];
                sender.userShell.stringValue = [settings valueForKey:@"userShell"];
                sender.NFSPath.stringValue = [settings valueForKey:@"NFSHome"];
            }
        }];
        [connection invalidate];
    }];
    
}


+(void)addUser:(User*)user toGroups:userGroups sender:(ODUController*)sender{
    NSString* progress = [NSString stringWithFormat:@"adding %@ to %@...",
                          user.userName, sender.serverName.stringValue];
    
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
                sender.statusUpdateUser.stringValue = [NSString stringWithFormat:@"Added/Updated %@",user.userName];
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
                sender.statusUpdate.textColor = [NSColor redColor];
                sender.statusUpdate.stringValue = [NSString stringWithFormat:@"Password reset for %@",user.userName];
            }
        }];
        [connection invalidate];
    }];

}
@end
