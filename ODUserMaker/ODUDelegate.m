//
//  AppDelegate.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUDelegate.h"
#import "SSKeychain.h"
#import "OpenDirectoryService.h"
#import "ODUserBridge.h"
#import "ODUDSQuery.h"

@implementation ODUDelegate

//-------------------------------------------------------------------
//  App Delegate
//-------------------------------------------------------------------

- (void)applicationDidFinishLaunching:(NSNotification* )aNotification
{
    NSError *error;
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    // Insert code here to initialize your application
    Server* server = [Server new];
    server.serverName = [defaults stringForKey:@"serverName"];
    server.diradminName = [defaults stringForKey:@"diradminName"];
    
    NSString* kcAccount = [NSString stringWithFormat:@"%@:%@",server.diradminName,server.serverName];
    
    server.diradminPass = [SSKeychain passwordForService:
                        [[NSBundle mainBundle] bundleIdentifier] account:kcAccount error:&error];
    
    if(!error){
        [ODUDSQuery getAuthenticatedDirectoryNode:server];
    }else{
        NSLog(@"Error: %@",error.localizedDescription);
    }
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication* )theApplication{
    return YES;
}

-(void)applicationWillTerminate:(NSNotification *)notification{

}

@end

