//
//  AppController.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppController : NSObject


// User Settings
@property (assign) IBOutlet NSTextField *userName;
@property (assign) IBOutlet NSTextField *emailDomain;
@property (assign) IBOutlet NSTextField *defaultGroup;

@property (assign) IBOutlet NSTextField *firstName;
@property (assign) IBOutlet NSTextField *lastName;
@property (assign) IBOutlet NSTextField *userCWID;
@property (assign) IBOutlet NSPopUpButton *userPreset;
@property (assign) IBOutlet NSButton *commStudent;

// File Settings
@property (assign) IBOutlet NSTextField *importFilePath;
@property (assign) IBOutlet NSButton *chooseImportFile;
@property (assign) IBOutlet NSTextField *userFilter;



@property (copy) NSURL *importFile;
@property (copy) NSString *exportFile;

// Sever Settings
@property (assign) IBOutlet NSTextField *serverName;
@property (assign) IBOutlet NSTextField *diradminName;
@property (assign) IBOutlet NSTextField *diradminPass;
@property (assign) IBOutlet NSButton *dsServerStatus;

// Progress Pannel
@property (assign) IBOutlet NSPanel *progressPanel;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSButton *progressCancelButton;
@property (copy) NSString *progressMessage;  // this is bound

// IBAction Buttons & Calls
@property (assign) IBOutlet NSButton *makeSingleUser;
@property (assign) IBOutlet NSButton *makeImportFile;
- (IBAction)makeSingleUserPressed:(id)sender;
- (IBAction)makeImportFilePressed:(id)sender;


@end
