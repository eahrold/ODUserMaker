//
//  AppController.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ODUController : NSObject{
    IBOutlet NSArrayController *dsGroupArrayController;
    IBOutlet NSArrayController *dsUserArrayController;
    IBOutlet NSArrayController *dsPresetArrayController;
    IBOutlet NSArrayController *groupMatchArrayController;
}

-(IBAction)makeSingleUserPressed:(id)sender;
-(IBAction)addGroupToUser:(id)sender;
-(IBAction)removeGroupFromUser:(id)sender;
-(IBAction)overrideUUID:(id)sender;

-(IBAction)makeMultiUserPressed:(id)sender;
-(IBAction)chooseImportFile:(id)sender;
-(IBAction)addGroupMatch:(id)sender;
-(IBAction)removeGroupMatch:(id)sender;

-(IBAction)resetPasswordPressed:(id)sender;

-(IBAction)refreshServerStatus:(id)sender;
-(IBAction)getSettingsForPreset:(id)sender;
-(IBAction)configrureUserPreset:(id)sender;

- (void)startProgressPanelWithMessage:(NSString*)message indeterminate:(BOOL)indeterminate;
- (void)stopProgressPanel;

//---------------------------------------------------
// User Settings
//---------------------------------------------------
@property (assign) IBOutlet NSTextField *userName;
@property (assign) IBOutlet NSTextField *emailDomain;
@property (assign) IBOutlet NSTextField *defaultGroup;

@property (assign) IBOutlet NSTextField   *firstName;
@property (assign) IBOutlet NSTextField   *lastName;
@property (assign) IBOutlet NSTextField   *userCWID;
@property (assign) IBOutlet NSPopUpButton *userPreset;

@property (assign) IBOutlet NSButton    *extraGroup;
@property (assign) IBOutlet NSComboBox  *extraGroupShortName;
@property (assign) IBOutlet NSTextField *extraGroupDescription;

@property (assign) IBOutlet NSButton    *overrideUID;
@property (assign) IBOutlet NSTextField *uuid;

@property (assign) IBOutlet NSTextField   *statusUpdateUser;


//---------------------------------------------------
// User Settings Preset
//---------------------------------------------------
@property (assign) IBOutlet NSWindow    *presetConfigSheet;
@property (assign) IBOutlet NSTextField *sharePoint;
@property (assign) IBOutlet NSTextField *sharePath;
@property (assign) IBOutlet NSTextField *NFSPath;
@property (assign) IBOutlet NSTextField *userShell;

//---------------------------------------------------
// Password Reset
//---------------------------------------------------
@property (assign) IBOutlet NSComboBox    *userList;
@property (assign) IBOutlet NSTextField   *statusUpdate;
@property (assign) IBOutlet NSTextField   *passWord;


//---------------------------------------------------
// File Settings
//---------------------------------------------------
@property (assign) IBOutlet NSTextField *importFilePath;
@property (assign) IBOutlet NSTextField *userFilter;

//---------------------------------------------------
// Group Settings
//---------------------------------------------------
@property (assign) IBOutlet NSPopUpButton *serverGroupList;
@property (assign) IBOutlet NSPopUpButton *serverGroupListSingleUser;

@property (assign) IBOutlet NSTextField *fileClassList;

@property (assign) IBOutlet NSPopUpButton *groupMatchEntries;
@property (assign) IBOutlet NSPopUpButton *groupEntries;

//---------------------------------------------------
// Sever Settings
//---------------------------------------------------
@property (assign) IBOutlet NSTextField *serverName;
@property (assign) IBOutlet NSTextField *diradminName;
@property (assign) IBOutlet NSTextField *diradminPass;

//---------------------------------------------------
// Server Status Settings
//---------------------------------------------------
@property (assign) IBOutlet NSButton *dsServerStatus;
@property (assign) IBOutlet NSTextField *dsStatusMessage;
@property (assign) IBOutlet NSProgressIndicator *dsServerStatusProgress;
@property (assign) IBOutlet NSButton *dsServerRefreshButton;

//---------------------------------------------------
// Progress Pannel
//---------------------------------------------------
@property (assign) IBOutlet NSPanel *progressPanel;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSButton *progressCancelButton;
@property (copy) NSString *progressMessage;  // <-- this is bound

@end
