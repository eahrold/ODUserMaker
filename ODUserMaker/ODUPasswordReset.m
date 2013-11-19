//
//  ODUPasswordReset.m
//  ODUserMaker
//
//  Created by Eldon on 11/18/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUPasswordReset.h"
#import "ODCommonHeaders.h"
#import "ODUDelegate.h"
#import "OpenDirectoryService.h"

@implementation ODUPasswordReset

-(void)resetPassword:(void (^)(NSError *error))pwResetReply{
    /* Set up the User Object */
    
    if([_userName isBlank]){
        [ODUAlerts showAlert:@"Name feild empty" withDescription:@"The name field can't be empty"];
        return;
    }
    
    if([_NewPassword isBlank]){
        [ODUAlerts showAlert:@"New Password Feild Empty" withDescription:@"The password field can't be empty"];
        return;
    }
    
    User* user = [User new];
    user.userName = _userName;
    user.userCWID = _NewPassword;
    
    [[NSApp delegate] startProgressPanelWithMessage:@"Resetting password..." indeterminate:YES];
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = [NSApp delegate];
    [connection resume];
    [[connection remoteObjectProxy] resetUserPassword:user withReply:^(NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[NSApp delegate] stopProgressPanel];
            pwResetReply(error);
        }];
        [connection invalidate];
    }];
    
}


@end
