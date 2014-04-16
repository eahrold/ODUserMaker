//
//  AppDelegate.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ODUDelegate : NSObject <NSApplicationDelegate>{
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSPanel *progressPanel;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSButton *progressCancelButtonBT;
@property (copy)            NSString *progressMessage;  // <-- this is bound

//---------------------------------------------------
// Progress Pannel
//---------------------------------------------------
- (void)startProgressPanelWithMessage:(NSString*)message indeterminate:(BOOL)indeterminate;
- (void)stopProgressPanel;

- (void)setProgress:(double)progress withMessage:(NSString*)message;
- (void)setProgress:(double)progress;

- (void)setProgressMsg:(NSString*)message;

@end
