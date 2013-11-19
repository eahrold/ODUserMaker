//
//  ODUSingleUser.m
//  ODUserMaker
//
//  Created by Eldon on 11/19/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUSingleUser.h"
#import "ODCommonHeaders.h"
#import "OpenDirectoryService.h"

@implementation ODUSingleUser

-(id)initWithUser:(User *)user andGroups:(NSArray *)groups{
    self = [super init];
    if(self){
        _user = user;
        _groups = groups;
    }
    return self;
}

-(void)addUser:(void (^)(NSError *))replyBlock{
    if(!_user){
        replyBlock([ODUError errorWithCode:ODUMCantAddUserToServer]);
        return;
    }
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = [NSApp delegate];
    [connection resume];
    [[connection remoteObjectProxy] addSingleUser:_user andGroups:_groups withReply:^(NSError *error){
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            replyBlock(error);
        }];
        [connection invalidate];
    }];

}

@end
