//
//  ODUFileConnection.m
//  ODUserMaker
//
//  Created by Eldon on 12/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUFileConnection.h"
#import "ODUError.h"
#import "ODUProgress.h"
#import "FileService.h"

@implementation ODUFileConnection

-(id)initWithServiceName:(NSString *)serviceName{
    self = [super initWithServiceName:serviceName];
    if (self) {
        self.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(FileService)];
        self.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
        self.exportedObject = [NSApp delegate];
        [self resume];
    }
    return self;
}


-(id)initConnection{
    self = [self initWithServiceName:kFileServiceName];
    return self;
}


-(void)makeUserList:(void (^)(ODRecordList* users, NSArray* groups,NSError *error))reply{
    [[self remoteObjectProxy] makeUserArray:_user importFile:_inFile exportFile:_outFile filter:_filter andGroupList:_groups withReply:^(NSArray* groups, ODRecordList* userlist, NSError* error){
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            reply(userlist,groups,error);
        }];
        [self invalidate];
    }];
}

-(void)makePasswordResetList:(void (^)(ODRecordList *, NSError *))reply{
    [[self remoteObjectProxy]makePasswordResetListFromFile:_inFile usernameColumn:_userNameColumn passwordColumn:_passWordColumn reply:^(ODRecordList *userlist, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            reply(userlist,error);
        }];
    }];
}

@end
