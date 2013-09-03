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
}

//---------------------------------------------------
//  User items
//---------------------------------------------------
@property (assign) IBOutlet NSPopUpButton *userPreset;
@property (assign) IBOutlet NSTextField *emailDomain;
@property (assign) IBOutlet NSTextField *defaultGroup;


//---------------------------------------------------
// Password Reset
//---------------------------------------------------
@property (assign) IBOutlet NSPopUpButton *serverUserList;

//---------------------------------------------------
//  Server items
//---------------------------------------------------

@property (assign) IBOutlet NSButton *dsServerStatus;
@property (assign) IBOutlet NSButton *refreshPreset;
@property (assign) IBOutlet NSProgressIndicator *presetStatus;


@property (assign) IBOutlet NSTextField *serverName;
@property (assign) IBOutlet NSTextField *diradminName;
@property (assign) IBOutlet NSTextField *diradminPass;

@property (assign) NSString *dsStatus;  // <----     this is bound


//---------------------------------------------------
//  file items
//---------------------------------------------------
@property (assign) IBOutlet NSTextField *importFilePath;

@property (assign) IBOutlet NSPopUpButton *serverGroupList;
@property (assign) IBOutlet NSPopUpButton *serverGroupListSingleUser;

@property (assign) IBOutlet NSPopUpButton *fileClassList;


//---------------------------------------------------
//  delegate items
//---------------------------------------------------

@property (nonatomic, assign) BOOL quitThread;
@property (assign) IBOutlet NSWindow *window;


@end
