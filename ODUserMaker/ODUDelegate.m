//
//  AppDelegate.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUDelegate.h"

@implementation ODUDelegate

#pragma mark - AppDelegate
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


#pragma mark - ProgressPanel
//-------------------------------------------
//  Progress Panel
//-------------------------------------------

- (void)startProgressPanelWithMessage:(NSString*)message indeterminate:(BOOL)indeterminate {
    /* Display a progress panel as a sheet */
    self.progressMessage = message;
    
    if (indeterminate) {
        [_progressIndicator setIndeterminate:YES];
        [_progressIndicator displayIfNeeded];
    } else {
        [_progressIndicator setUsesThreadedAnimation:YES];
        [_progressIndicator setIndeterminate:NO];
        [_progressIndicator setDoubleValue:0.0];
        [_progressIndicator displayIfNeeded];
    }
    
    [_progressIndicator startAnimation:self];
    [_progressCancelButtonBT setEnabled:YES];
    [NSApp beginSheet:_progressPanel
       modalForWindow:_window
        modalDelegate:self
       didEndSelector:nil
          contextInfo:NULL];
}

- (void)stopProgressPanel {
    self.progressMessage = @"";
    [self.progressIndicator setDoubleValue:0.0];
    [self.progressPanel orderOut:self];
    [NSApp endSheet:_progressPanel returnCode:0];
}


- (void)setProgressMsg:(NSString*)message{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.progressMessage = message;
    }];
}

- (void)setProgress:(double)progress withMessage:(NSString*)message {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [_progressIndicator incrementBy:progress];
        self.progressMessage = message;
    }];
}

- (void)setProgress:(double)progress {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [_progressIndicator incrementBy:progress];
    }];
}

@end

