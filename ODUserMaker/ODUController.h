//
//  AppController.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ODUDirectoryConnection.h"

@interface ODUController : NSObject <ODUAuthenticatorDelegate, ODUSQueryDelegate>{
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

//---------------------------------------------------
// ODUser Settings
//---------------------------------------------------
@property (assign) IBOutlet NSTextField   *userNameTF;
@property (assign) IBOutlet NSTextField   *firstNameTF;
@property (assign) IBOutlet NSTextField   *lastNameTF;
@property (assign) IBOutlet NSTextField   *userCWIDTF;
@property (assign) IBOutlet NSTextField   *uuidTF;
@property (assign) IBOutlet NSTextField   *statusUpdateUserTF;
@property (assign) IBOutlet NSButton      *extraGroupBT;
@property (assign) IBOutlet NSButton      *overrideUIDBT;
@property (assign) IBOutlet NSPopUpButton *serverGroupListSingleUserPUB;
@property (assign) IBOutlet NSPopUpButton *groupEntriesPUB;

//---------------------------------------------------
// Common Settings
//---------------------------------------------------
@property (assign) IBOutlet NSTextField   *emailDomainTF;
@property (assign) IBOutlet NSTextField   *defaultGroupTF;
@property (assign) IBOutlet NSButton      *chooseUserPresetBT;


//---------------------------------------------------
// ODUser Settings Panel Items
//---------------------------------------------------
@property (assign) IBOutlet NSWindow      *presetConfigSheet;
@property (assign) IBOutlet NSTextField   *sharePointTF;
@property (assign) IBOutlet NSTextField   *sharePathTF;
@property (assign) IBOutlet NSTextField   *NFSPathTF;
@property (assign) IBOutlet NSTextField   *userShellTF;
@property (assign) IBOutlet NSComboBox    *extraGroupShortNameCB;
@property (assign) IBOutlet NSTextField   *extraGroupDescriptionTF;
@property (assign) IBOutlet NSPopUpButton *userPresetPUB;

//---------------------------------------------------
// Password Reset
//---------------------------------------------------
@property (assign) IBOutlet NSTextField   *NewPassWordTF;
@property (assign) IBOutlet NSTextField   *passwordResetStatusTF;
@property (assign) IBOutlet NSComboBox    *userListCB;

//---------------------------------------------------
// File Settings
//---------------------------------------------------
@property (assign) IBOutlet NSTextField   *importFilePathTF;
@property (assign) IBOutlet NSTextField   *userFilterTF;

//---------------------------------------------------
// Group Settings
//---------------------------------------------------
@property (assign) IBOutlet NSTextField   *groupMatchTF;
@property (assign) IBOutlet NSPopUpButton *serverGroupListPUB;
@property (assign) IBOutlet NSPopUpButton *groupMatchEntriesPUB;

//---------------------------------------------------
// Sever Settings
//---------------------------------------------------
@property (assign) IBOutlet NSTextField   *serverNameTF;
@property (assign) IBOutlet NSTextField   *diradminNameTF;
@property (assign) IBOutlet NSTextField   *diradminPassTF;

//---------------------------------------------------
// Server Status Settings
//---------------------------------------------------
@property (assign) IBOutlet NSTextField   *dsStatusMessageTF;
@property (assign) IBOutlet NSButton      *dsServerStatusBT;
@property (assign) IBOutlet NSButton      *dsServerRefreshButtonBT;
@property (assign) IBOutlet NSProgressIndicator *dsServerStatusProgress;


@end
