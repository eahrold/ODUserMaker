//
//  AppDelegate.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

//---------------------------------------------------
//  User items
//---------------------------------------------------
@property (assign) IBOutlet NSPopUpButton *userPreset;
@property (assign) IBOutlet NSTextField *emailDomain;
@property (assign) IBOutlet NSTextField *defaultGroup;

//---------------------------------------------------
//  Server items
//---------------------------------------------------

@property (assign) IBOutlet NSButton *dsServerStatus;
@property (assign) IBOutlet NSButton *refreshPreset;
@property (assign) IBOutlet NSProgressIndicator *presetStatus;


@property (assign) IBOutlet NSTextField *serverName;
@property (assign) IBOutlet NSTextField *diradminName;
@property (assign) IBOutlet NSTextField *diradminPass;

@property (copy) NSString *dsStatus;  // this is bound

- (IBAction)editServerName:(id)sender;


//---------------------------------------------------
//  file items
//---------------------------------------------------
@property (assign) IBOutlet NSTextField *importFilePath;
@property (assign) IBOutlet NSPopUpButton *serverGroupList;
@property (assign) IBOutlet NSPopUpButton *fileClassList;


//---------------------------------------------------
//  delegate items
//---------------------------------------------------

@property (nonatomic, assign) BOOL quitThread;
@property (assign) IBOutlet NSWindow *window;

-(void)tryToSetInterface:(NSTextField*)filed withSetting:(NSString*)string;

@end
