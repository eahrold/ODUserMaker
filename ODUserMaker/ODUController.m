//
//  AppController.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUController.h"
#import "ODUDelegate.h"
#import "ODCommonHeaders.h"
#import "ODUSingleUser.h"
#import "ODUUserList.h"
#import "ODUPasswordReset.h"
#import "FileService.h"
#import "OpenDirectoryService.h"

@implementation ODUController{
    NSMutableArray *groups;
}
@synthesize authenticator,querier;


-(void)awakeFromNib{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshServerStatus:)
                                                 name:@"appLaunched"
                                               object:nil];
}


#pragma mark - Add Single User
-(void)makeSingleUserPressed:(id)sender{
    NSError* error = nil;
    
    if(!_dsServerStatusBT.state){
        error = [ODUError errorWithCode:ODUMNotAuthenticated];
        [ODUAlerts showErrorAlert:error];
        return;
    }
    
    NSArray* requiredFields = @[_firstNameTF,_lastNameTF,_userNameTF,_userCWIDTF,_emailDomainTF,_defaultGroupTF];
    
    for (NSTextField* i in requiredFields){
        if([i isBlank]){
            [ODUAlerts showAlert:@"Missing fileds" withDescription:@"Please fill out all fields"];
            return;
        }
    }
    
    /* Set up the User Object */
    User* user = nil;
    user = [User new];
    user.firstName = _firstNameTF.stringValue;
    user.lastName = _lastNameTF.stringValue;
    user.userName = _userNameTF.stringValue;
    user.userCWID = _userCWIDTF.stringValue;
    user.emailDomain = _emailDomainTF.stringValue;
    user.primaryGroup = _defaultGroupTF.stringValue;
    user.userPreset = [ _userPresetPUB titleOfSelectedItem];
    user.userCount = [NSNumber numberWithInt:1];
    user.userShell = _userShellTF.stringValue;
    user.sharePath = _sharePathTF.stringValue;
    user.sharePoint = _sharePointTF.stringValue;
    user.nfsPath = _NFSPathTF.stringValue;
    
    NSMutableArray* ug = [NSMutableArray new];
    
    if(_extraGroupBT.state){
        if([_extraGroupShortNameCB isNotBlank]){
            [ug addObject:_extraGroupShortNameCB.stringValue];
        }
    }
    
    //do get other groups...
    for (NSString* i in _groupEntriesPUB.itemTitles){
        [ug addObject:i];
    }
    
    //then...
    NSArray* userGroups = ug;
    
    if(_overrideUIDBT.state){
        NSNumberFormatter* f = [NSNumberFormatter new];
        if([f numberFromString:_uuidTF.stringValue]){
            user.userUUID = _uuidTF.stringValue;
        }else{
            [ODUAlerts showAlert:@"The UID Is not Usable" withDescription:@"The UID you specifiied is not a number.  Please check it and try again"];
            return;
        }
    }
    
    if(_extraGroupBT.state){
        user.keyWord = _extraGroupDescriptionTF.stringValue;
    }
    
    [[NSApp delegate]startProgressPanelWithMessage:@"Adding User..." indeterminate:YES];
    ODUSingleUser* addSingleUser = [[ODUSingleUser alloc]initWithUser:user andGroups:userGroups];
    [addSingleUser addUser:^(NSError *error) {
        [[NSApp delegate]stopProgressPanel];
        if(error){
            [ODUAlerts showErrorAlert:error];
        }
    }];
}

-(IBAction)addGroupToUser:(id)sender{
    [_groupEntriesPUB insertItemWithTitle:[_serverGroupListSingleUserPUB titleOfSelectedItem] atIndex:0];
    [_groupEntriesPUB selectItemAtIndex:0];
}

-(IBAction)removeGroupFromUser:(id)sender{
    if( _groupEntriesPUB.indexOfSelectedItem > -1){
        [_groupEntriesPUB removeItemAtIndex:[_groupEntriesPUB indexOfSelectedItem]];
    }
}

-(IBAction)overrideUUID:(id)sender{
    if([_overrideUIDBT state]){
        [_uuidTF setHidden:FALSE];
    }else{
        [_uuidTF setHidden:TRUE];
        [_uuidTF setStringValue:@""];
    }
}



#pragma mark - Add Users List
- (IBAction)makeMultiUserPressed:(id)sender{
    NSButton* button = sender;
    NSError* error = nil;
    
    if(!_dsServerStatusBT.state){
        [ODUAlerts showErrorAlert:[ODUError errorWithCode:ODUMNotAuthenticated]];
        return;
    }
    
    if([_importFilePathTF isBlank]){
        [ODUAlerts showErrorAlert:[ODUError errorWithCode:ODUMNoFileSelected]];
        return;
    }
    
   
    
    /*set up the user object*/
    User* user = [User new];
    user.emailDomain = _emailDomainTF.stringValue;
    user.primaryGroup = _defaultGroupTF.stringValue;
    user.userPreset = [ _userPresetPUB titleOfSelectedItem];
    user.importFilePath = [_importFilePathTF stringValue];
        
    user.keyWord = @"";
    
    if(_userFilterTF.isNotBlank){
        user.userFilter = _userFilterTF.stringValue;
    }else{
        user.userFilter = @"";
    }
    
    /* Set up the import FileHandles */
    NSURL * importFileURL = [NSURL fileURLWithPath:_importFilePathTF.stringValue];
    user.importFileHandle = [NSFileHandle fileHandleForReadingFromURL:importFileURL error:&error];
    ODUUserList* makeList = [ODUUserList new];
    

    if([button.title isEqualToString:@"Import Users"]){
        [[NSApp delegate] startProgressPanelWithMessage:@"Importing Users..." indeterminate:YES];
        [makeList setUser:user];
        [makeList setGroups:groups];
        [makeList addUserList:^(NSError *error) {
            [[NSApp delegate] stopProgressPanel];
            if(error){
                [ODUAlerts showErrorAlert:error];
            }
        }];
        return;
    }
    
    if([button.title isEqualToString:@"Make DSImport File"]){
        NSURL* exportFileURL =[self openSavePanel];
        
        if(!exportFileURL){
            [ODUAlerts showErrorAlert:[ODUError errorWithCode:ODUMWriteFileError]];
            return;
        }
        
        [[NSData data] writeToURL:exportFileURL options:0 error:&error];
        if(error){
            [ODUAlerts showErrorAlert:error];
            return;
        }

        user.exportFile = [NSFileHandle fileHandleForWritingToURL:exportFileURL error:&error];
        
        if(error){
            [ODUAlerts showErrorAlert:error];
            return;
        }

        [[NSApp delegate] startProgressPanelWithMessage:@"Creating DSImport File..." indeterminate:YES];

        [makeList setUser:user];
        [makeList setGroups:groups];
        
        [makeList addUserList:^(NSError *error) {
            [[NSApp delegate] stopProgressPanel];
            if(error){
                [ODUAlerts showErrorAlert:error];
            }
        }];
    }
}

-(IBAction)cancelUserImport:(id)sender{
    [ODUUserList cancel];
}

-(IBAction)chooseImportFile:(id)sender{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:NO];
    
    [openPanel beginSheetModalForWindow:[[NSApplication sharedApplication]mainWindow] completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            _importFilePathTF.stringValue = [openPanel URL].path;
        }
    }];
    
}


-(IBAction)addGroupMatch:(id)sender{
    NSString* match = _groupMatchTF.stringValue;
    NSString* group = _serverGroupListPUB.titleOfSelectedItem;
    
    if(!groups)groups = [[NSMutableArray alloc] init];
    if([group isBlank]||[match isBlank])return;
    
    NSString* description =[NSString stringWithFormat:@"%@:%@",group,match];
    NSDictionary * dict = @{@"description":description,@"group":group,@"match":match};

    [groups addObject:dict];
    [groups sortUsingDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"group" ascending:YES], nil]];
    
    [groupMatchArrayController setContent:groups];

}

-(IBAction)removeGroupMatch:(id)sender{
    if(_groupMatchEntriesPUB.indexOfSelectedItem > -1){
        [groups removeObjectAtIndex:[_groupMatchEntriesPUB indexOfSelectedItem]];
        [groupMatchArrayController setContent:groups];
    }
}


#pragma mark - Reset Password
- (IBAction)resetPasswordPressed:(id)sender{
    NSError* error = nil;
    
    if(!_dsServerStatusBT.state){
        error = [ODUError errorWithCode:ODUMNotAuthenticated];
        [ODUAlerts showErrorAlert:error];
        return;
    }
    
    ODUPasswordReset* resetter = [ODUPasswordReset new];
    
    resetter.userName = [_userListCB blankCheck];
    resetter.NewPassword = [_NewPassWordTF blankCheck];
    
    [resetter resetPassword:^(NSError *error) {
        if(error){
            NSLog(@"Error: %@",[error localizedDescription]);
            [ODUAlerts showErrorAlert:error];
        }else{
            _passwordResetStatusTF.textColor = [NSColor greenColor];
            _passwordResetStatusTF.stringValue = [NSString stringWithFormat:@"Password reset for %@",resetter.userName];
        }
    }];
}



#pragma mark - Server Status IBActions
//-------------------------------------------
//  Server Status IBActions
//-------------------------------------------
-(IBAction)refreshServerStatus:(id)sender{
    if(!authenticator){
        authenticator = [[ODUAuthenticator alloc]initWithDelegate:self];
    }
    
    [_dsServerStatusProgress startAnimation:nil];
    [_dsServerStatusProgress setHidden:NO];
    [_dsServerRefreshButtonBT setHidden:YES];
    
    [authenticator authenticateToNode];
    
}


- (IBAction)editServerName:(id)sender{
    if(![_serverNameTF.stringValue isEqualToString:authenticator.serverName] ||
       ![_diradminNameTF.stringValue isEqualToString:authenticator.diradminName]){
        [authenticator getKeyChainPassword];
    }
}

-(IBAction)getSettingsForPreset:(id)sender{
    if(!querier){
        querier = [[ODUDSQuery alloc]initWithDelegate:self];
    }

    [querier getSettingsForPreset];
}



#pragma mark - Authenticator Delegate
//-------------------------------------------
//  Authenticator Delegate
//-------------------------------------------
-(void)didRecieveStatusUpdate:(OSStatus)status{
    [_dsServerStatusProgress stopAnimation:nil];
    [_dsServerStatusProgress setHidden:YES];
    [_dsServerRefreshButtonBT setHidden:NO];
    
    if(status < 0){
        [_dsServerStatusBT setImage:[NSImage imageNamed:@"connected-offline.tiff"]];
    }else{
        if(!querier){
            querier = [[ODUDSQuery alloc]initWithDelegate:self];
        }
        [querier getDSUserPresets];
        [querier getDSUserList];
        [querier getDSGroupList];
    }
    
    NSString* sv;
    switch(status){
        case ODUNoNode: sv = @"Could Not Contact Server";
            break;
        case ODUUnauthenticatedLocal:sv = ODUUnauthenticatedLocalMSG;
            break;
        case ODUUnauthenticatedProxy:sv = ODUUnauthenticatedProxyMSG;
            break;
        case ODUAuthenticatedLocal:sv = ODUAuthenticatedLocalMSG;
            [_dsServerStatusBT setImage:[NSImage imageNamed:@"connected-local.tiff"]];
            break;
        case ODUAuthenticatedProxy:sv = ODUAuthenticatedProxyMSG;
            [_dsServerStatusBT setImage:[NSImage imageNamed:@"connected-proxy.tiff"]];
            break;
        default: sv = @""; [_dsServerStatusBT setImage:nil ];break;
            
    }
    
    _dsStatusMessageTF.stringValue = sv;

}

-(void)didGetPassWordFromKeychain:(NSString *)password{
    _diradminPassTF.stringValue = password;
}

-(NSString *)nameOfDiradmin:(ODUAuthenticator *)authenticator{
    return _diradminNameTF.blankCheck;

}

-(NSString *)nameOfServer:(ODUAuthenticator *)authenticator{
    return _serverNameTF.blankCheck;
}

-(NSString *)passwordForDiradmin:(ODUAuthenticator *)authenticator{
    return _diradminPassTF.blankCheck;
}


#pragma mark - ODUDSQueryDelegate
//-------------------------------------------
//  Querier Delegate
//-------------------------------------------
-(void)didGetDSGroupList:(NSArray *)dsgroups{
    [dsGroupArrayController setContent:dsgroups];
    NSString* exg = [[NSUserDefaults standardUserDefaults]objectForKey:@"extraGroup"];
    
    if([exg isNotBlank])
        _extraGroupShortNameCB.stringValue = exg;
    else
        _extraGroupShortNameCB.stringValue = @"staff";
}

-(void)didGetDSUserList:(NSArray *)dsusers{
    [dsUserArrayController setContent:dsusers];
}

-(void)didGetDSUserPresets:(NSArray *)dspresets{
    [dsPresetArrayController setContent:dspresets];
    if(dspresets.count){
        [_chooseUserPresetBT setTitle:[dspresets[0] objectForKey:@"presetName"]];
    }else{
        [_chooseUserPresetBT setTitle:@"Configure"];
    }
    [querier getSettingsForPreset];
}

-(void)didGetSettingsForPreset:(NSDictionary *)settings{
    [_chooseUserPresetBT setTitle:_userPresetPUB.titleOfSelectedItem];
    _sharePointTF.stringValue = settings[@"sharePoint"];
    _sharePathTF.stringValue  = settings[@"sharePath"];
    _userShellTF.stringValue  = settings[@"userShell"];
    _NFSPathTF.stringValue    = settings[@"NFSHome"];
}

-(NSString *)nameOfPreset{
    return _userPresetPUB.titleOfSelectedItem.blankCheck;
}



#pragma mark - Sheets and Panels
//-------------------------------------------
//  Open and Save Panels
//-------------------------------------------
-(NSURL*)openSavePanel{
    NSURL* url;
    NSSavePanel* savePanel = [NSSavePanel savePanel];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"txt"]];
    [savePanel setNameFieldStringValue:@"dsimport.txt"];
    
    if([savePanel runModal] == NSOKButton){
        url = [savePanel URL];
    }
    
    return url;
}



//-------------------------------------------
//  Preset Config Shteet
//-------------------------------------------
-(IBAction)configrureUserPreset:(id)sender{
    [NSApp beginSheet:_presetConfigSheet
       modalForWindow:[[NSApplication sharedApplication]mainWindow]
        modalDelegate:self
       didEndSelector:NULL
          contextInfo:NULL];
}

- (IBAction)settingsDone:(id)sender{
    [_presetConfigSheet orderOut:self];
    [NSApp endSheet:_presetConfigSheet returnCode:0];
    
    if(![_extraGroupDescriptionTF.stringValue isEqualToString:@""]){
        _extraGroupBT.title = _extraGroupDescriptionTF.stringValue;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:_extraGroupShortNameCB.stringValue forKey:@"extraGroup"];
}


@end
