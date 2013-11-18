//
//  AppDelegate.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUDelegate.h"

@implementation ODUDelegate

//-------------------------------------------------------------------
//  App Delegate
//-------------------------------------------------------------------

- (void)applicationDidFinishLaunching:(NSNotification* )aNotification
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"appLaunched"
     object:self];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication* )theApplication{
    return YES;
}

-(void)applicationWillTerminate:(NSNotification *)notification{

}

@end

