//
//  ODUPasswordReset.m
//  ODUserMaker
//
//  Created by Eldon on 11/18/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUPasswordReset.h"
#import "ODUController.h"
#import "SecuredObjects.h"
#import "OpenDirectoryService.h"
#import "ODUProgress.h"
#import "ODUAlerts.h"

@implementation ODUPasswordReset

-(void)resetPassword:(ODUController *)sender{
    /* Set up the User Object */
    
    if([_userName isEqualToString:@""]){
        [ODUAlerts showAlert:@"Name feild empty" withDescription:@"The name field can't be empty"];
        return;
    }
    
    if([_NewPassword isEqualToString:@""]){
        [ODUAlerts showAlert:@"New Password Feild Empty" withDescription:@"The password field can't be empty"];
        return;
    }
    
    User* user = [User new];
    user.userName = _userName;
    user.userCWID = _NewPassword;
    
    [sender startProgressPanelWithMessage:@"Resetting password..." indeterminate:YES];
    sender.passwordResetStatusTF.stringValue = @"";

    
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
                sender.passwordResetStatusTF.textColor = [NSColor redColor];
                sender.passwordResetStatusTF.stringValue = [NSString stringWithFormat:@"Password reset for %@",user.userName];
            }
        }];
        [connection invalidate];
    }];
    
}


@end
