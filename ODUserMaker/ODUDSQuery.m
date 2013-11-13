//
//  ODUDSQuery.m
//  ODUserMaker
//
//  Created by Eldon on 11/12/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUDSQuery.h"
#import "SecuredObjects.h"
#import "OpenDirectoryService.h"
#import "ODUStatus.h"

@implementation ODUDSQuery

+(void)getAuthenticatedDirectoryNode:(Server*)server{
    /* don't bother checking untill everything is in place */
    
    if([server.serverName isEqualToString:@""] ||
       [server.diradminName isEqualToString:@""] ||
       [server.diradminPass isEqualToString:@""]){
        return;
        NSLog(@"Something is missing");
    }
  
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] checkServerStatus:server withReply:^(OSStatus status)  {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [ODUStatus sharedStatus].serverStatus = status;
            }
        ];
        [connection invalidate];
    }];

}

+(void)getDSUserList{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
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
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
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
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
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


@end
