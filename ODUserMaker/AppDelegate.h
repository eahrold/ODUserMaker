//
//  AppDelegate.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, assign) BOOL quitThread;

@property (copy) NSString *dsStatus;  // this is bound
@property (assign) IBOutlet NSButton *dsServerStatus;

@property (assign) IBOutlet NSPopUpButton *userPreset;

@property (assign) IBOutlet NSTextField *serverName;
@property (assign) IBOutlet NSTextField *diradminName;
@property (assign) IBOutlet NSTextField *diradminPass;


@property (assign) IBOutlet NSWindow *window;

- (IBAction)editServerName:(id)sender;


@end
