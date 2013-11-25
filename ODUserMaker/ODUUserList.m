//
//  ODUUserList.m
//  ODUserMaker
//
//  Created by Eldon on 11/19/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUUserList.h"
#import "ODCommonHeaders.h"
#import "ODUDelegate.h"
#import "OpenDirectoryService.h"
#import "FileService.h"

@implementation ODUUserList

-(id)initWithUser:(User *)user andGroups:(NSArray *)groups{
    self = [super init];
    if(self){
        _user = user;
        _groups = groups;
    }
    return self;
}

-(void)addUserList:(void (^)(NSError *))replyBlock{
    NSXPCConnection* fileServiceConnection = [[NSXPCConnection alloc] initWithServiceName:kFileServiceName];
    fileServiceConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(FileService)];
    fileServiceConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    fileServiceConnection.exportedObject = [NSApp delegate];
    [fileServiceConnection resume];
    [[fileServiceConnection remoteObjectProxy] makeUserArray:_user andGroupList:_groups withReply:^(NSArray* groupList,NSArray* userlist, NSError* error){
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [fileServiceConnection invalidate];
            if(error || _user.exportFile ){
                replyBlock(error);
                return;
            }else{
                [[[NSApp delegate] progressIndicator] setIndeterminate:NO];
                [[[NSApp delegate] progressIndicator] setUsesThreadedAnimation:YES];
                
                _user.userList = userlist;
                _user.groupList = groupList;

                NSXPCConnection* directoryServiceConnection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
                directoryServiceConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
                
                directoryServiceConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
                directoryServiceConnection.exportedObject = [NSApp delegate];
                
                [directoryServiceConnection resume];
                [[directoryServiceConnection remoteObjectProxy] addListOfUsers:_user withReply:^(NSError *error) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        replyBlock(error);
                    }];
                    DLog(@"Invalidated DS Connection");
                    [directoryServiceConnection invalidate];
                }];
            }
        }];
    }];
}

+(void)cancel{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    [connection resume];
    [[connection remoteObjectProxy] cancelImportStatus:^(OSStatus connected) {
        [[NSApp delegate] stopProgressPanel];
        [connection invalidate];
    }];
}

@end
