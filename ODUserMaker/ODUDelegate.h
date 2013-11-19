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


//---------------------------------------------------
// Progress Pannel
//---------------------------------------------------
- (void)startProgressPanelWithMessage:(NSString*)message indeterminate:(BOOL)indeterminate;
- (void)stopProgressPanel;

@property (assign) IBOutlet NSPanel *progressPanel;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSButton *progressCancelButtonBT;
@property (copy) NSString *progressMessage;  // <-- this is bound

@end
