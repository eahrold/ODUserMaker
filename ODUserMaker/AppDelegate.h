//
//  AppDelegate.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>{
    IBOutlet NSArrayController *dsGroupArrayController;
    IBOutlet NSArrayController *dsUserArrayController;
    IBOutlet NSArrayController *dsUserPresetController;

}

//---------------------------------------------------
//  User items
//---------------------------------------------------
@property (assign) IBOutlet NSPopUpButton *userPreset;
@property (assign) IBOutlet NSTextField *emailDomain;
@property (assign) IBOutlet NSTextField *defaultGroup;

//---------------------------------------------------
// User Settings Preset
//---------------------------------------------------
@property (assign) IBOutlet NSWindow *settings;
@property (assign) IBOutlet NSTextField *usingPreset;
@property (assign) IBOutlet NSTextField *sharePoint;
@property (assign) IBOutlet NSTextField *sharePath;
@property (assign) IBOutlet NSTextField *NFSPath;
@property (assign) IBOutlet NSTextField *userShell;

@property (assign) IBOutlet NSButton *extraGroup;
@property (assign) IBOutlet NSComboBox *extraGroupShortName;
@property (assign) IBOutlet NSTextField *extraGroupDescription;

@property (assign) IBOutlet NSButton *choosePresetButton;



//---------------------------------------------------
// Password Reset
//---------------------------------------------------
@property (assign) IBOutlet NSComboBox *userList;
@property (assign) IBOutlet NSTextField   *statusUpdate;

//---------------------------------------------------
//  Server items
//---------------------------------------------------

@property (assign) IBOutlet NSButton *dsServerStatus;
@property (assign) IBOutlet NSButton *refreshPreset;
@property (assign) IBOutlet NSProgressIndicator *presetStatus;
@property (assign) IBOutlet NSProgressIndicator *userListStatus;



@property (assign) IBOutlet NSTextField *serverName;
@property (assign) IBOutlet NSTextField *diradminName;
@property (assign) IBOutlet NSTextField *diradminPass;

@property (assign) IBOutlet NSTextField *dsStatusTF;
@property (assign) NSString *dsStatus;  // <----     this is bound


//---------------------------------------------------
//  file items
//---------------------------------------------------
@property (assign) IBOutlet NSTextField *importFilePath;

@property (assign) IBOutlet NSPopUpButton *serverGroupList;
@property (assign) IBOutlet NSPopUpButton *serverGroupListSingleUser;


//---------------------------------------------------
//  delegate items
//---------------------------------------------------

@property (assign) IBOutlet NSWindow *window;

@end
