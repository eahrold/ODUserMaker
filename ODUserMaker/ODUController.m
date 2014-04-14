//
//  AppController.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUController.h"
#import "ODUDelegate.h"
#import "ODUDirectoryConnection.h"
#import "ODUFileConnection.h"
#import "ODUAlerts.h"
#import "SSKeychain.h"
#import "NSString(TextField)+isNotBlank.h"
#import "ODManager.h"

@implementation ODUController{
    NSMutableArray *_groups;
}


-(void)awakeFromNib{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshServerStatus:)
                                                 name:@"appLaunched"
                                               object:nil];
}


#pragma mark - Add Single ODUser
-(void)makeSingleUserPressed:(id)sender{
    NSError* error = nil;
    
    if(!_dsServerStatusBT.state){
        error = [ODUError errorWithCode:ODUMNotAuthenticated];
        [ODUAlerts showErrorAlert:error];
        return;
    }
    
    NSArray* fields = @[_firstNameTF,
                        _lastNameTF,
                        _userNameTF,
                        _userCWIDTF,
                        _emailDomainTF,
                        _defaultGroupTF];
    
    if(!fields.requiredFields){
        [ODUAlerts showAlert:@"Missing Fileds" withDescription:@"Please fill out all fields"];
        return;
    }

    
    /* Set up the ODUser Object */
    ODUser* user = nil;
    user = [ODUser new];
    user.firstName = _firstNameTF.stringValue;
    user.lastName = _lastNameTF.stringValue;
    user.userName = _userNameTF.stringValue;
    user.passWord = _userCWIDTF.stringValue;
    user.emailDomain = _emailDomainTF.stringValue;
    user.primaryGroup = _defaultGroupTF.stringValue;
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
            user.uid = _uuidTF.stringValue;
        }else{
            [ODUAlerts showAlert:@"The UID Is not Usable" withDescription:@"The UID you specifiied is not a number.  Please check it and try again"];
            return;
        }
    }
    
    if(_extraGroupBT.state){
        user.keyWord = _extraGroupDescriptionTF.stringValue;
    }
    
    [[NSApp delegate] startProgressPanelWithMessage:@"Adding ODUser..." indeterminate:YES];
    ODUDirectoryConnection* addSingleUser = [[ODUDirectoryConnection alloc]initConnection];
    [addSingleUser addUser:user andGroups:userGroups reply:^(NSError *error) {
        [[NSApp delegate] stopProgressPanel];
        if(error){
            [ODUAlerts showErrorAlert:error];
        }
    }];
}

#pragma mark --Config IBActions

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



#pragma mark - Add ODUsers List
- (IBAction)makeMultiUserPressed:(NSButton*)sender{
    if(!_dsServerStatusBT.state){
        [ODUAlerts showErrorAlert:[ODUError errorWithCode:ODUMNotAuthenticated]];
        return;
    }
    
    if(_importFilePathTF.isBlank){
        [ODUAlerts showErrorAlert:[ODUError errorWithCode:ODUMNoFileSelected]];
        return;
    }
    
    /*set up the user object*/
    ODUser* user = [ODUser new];
    user.emailDomain = _emailDomainTF.blankIsNil;
    user.primaryGroup = _defaultGroupTF.blankIsNil;

    /*get any values specified in the config panel*/
    user.sharePath  = _sharePathTF.blankIsNil;
    user.sharePoint = _sharePointTF.blankIsNil;
    user.userShell  = _userShellTF.blankIsNil;
    user.nfsPath    = _NFSPathTF.blankIsNil;
    
    ODUFileConnection* fs = [[ODUFileConnection alloc]initConnection];
    fs.user = user;
    fs.groups = _groups;
    fs.inFile = _importFilePathTF.blankIsNil;
    fs.filter = _userFilterTF.stringValue;;
    
    [[[NSApp delegate] progressIndicator] setIndeterminate:YES];
    [[[NSApp delegate] progressIndicator] setUsesThreadedAnimation:YES];
    
    /*before we send the groups array off arrange the order*/
    [_groups sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"group"
                                                                  ascending:YES]]];
    
    if([sender.title isEqualToString:@"Import Users"]){
        [[NSApp delegate] startProgressPanelWithMessage:@"Importing Users..." indeterminate:YES];
        [fs makeUserList:^(ODRecordList *users, NSArray *groups, NSError *error) {
            if(error){
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [[NSApp delegate] stopProgressPanel];
                    [ODUAlerts showErrorAlert:error];
                }];
            }else{
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [[[NSApp delegate] progressIndicator] setIndeterminate:NO];
                }];
                ODUDirectoryConnection* ds = [[ODUDirectoryConnection alloc]initConnection];
                [ds importUserList:users withGroups:groups reply:^(NSError *error) {
                    [[NSApp delegate] stopProgressPanel];
                    if(error){
                        [ODUAlerts showErrorAlert:error];
                    }else{
                        [ODUAlerts showAlert:@"Import Complete" withDescription:@""];
                    }
                }];
            }
        }];
    }
    
    if([sender.title isEqualToString:@"Make DSImport File"]){
        NSError* error = nil;

        NSURL* exportFileURL = [self openSavePanel];
        if(!exportFileURL){
            [ODUAlerts showErrorAlert:[ODUError errorWithCode:ODUMWriteFileError]];
            return;
        }
        
        [[NSData data] writeToURL:exportFileURL options:0 error:&error];
        if(error){
            [ODUAlerts showErrorAlert:error];
            return;
        }
        fs.outFile = [NSFileHandle fileHandleForWritingToURL:exportFileURL error:&error];
        
        if(error){
            [ODUAlerts showErrorAlert:error];
            return;
        }
        [[NSApp delegate] startProgressPanelWithMessage:@"Creating DSImport File..." indeterminate:YES];
        [fs makeUserList:^(ODRecordList *users, NSArray *groups, NSError *error) {
            [[NSApp delegate] stopProgressPanel];
            if(error){
                [ODUAlerts showErrorAlert:error];
            }
        }];
    }
}

-(IBAction)cancelUserImport:(id)sender{
    [ODUDirectoryConnection cancelImport];
}

#pragma mark -- Config IBActions
-(IBAction)chooseImportFile:(id)sender{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:NO];
    
    [openPanel beginSheetModalForWindow:[[NSApplication sharedApplication]mainWindow] completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            _importFilePathTF.stringValue = [[openPanel URL] path];
        }
    }];
    
}

-(IBAction)addGroupMatch:(id)sender{
    NSString* match = _groupMatchTF.stringValue;
    NSString* group = _serverGroupListPUB.titleOfSelectedItem;
    
    if(!_groups)_groups = [[NSMutableArray alloc] init];
    if([group isBlank]||[match isBlank])return;
    
    NSString* description =[NSString stringWithFormat:@"%@:%@",group,match];
    NSDictionary * dict = @{@"description":description,@"group":group,@"match":match};
    
    [_groups insertObject:dict atIndex:0];
    [groupMatchArrayController setContent:_groups];
    
}

-(IBAction)removeGroupMatch:(id)sender{
    if(_groupMatchEntriesPUB.numberOfItems){
        [_groups removeObjectAtIndex:[_groupMatchEntriesPUB indexOfSelectedItem]];
        [groupMatchArrayController setContent:_groups];
    }
}

#pragma mark - Reset Password
- (IBAction)resetPasswordPressed:(id)sender{
    NSError* error;
    
    if(!_dsServerStatusBT.state){
        error = [ODUError errorWithCode:ODUMNotAuthenticated];
        [ODUAlerts showErrorAlert:error];
        return;
    }
    
    ODUser* user = [ODUser new];
    user.passWord = _NewPassWordTF.blankIsNil;
    user.userName = _userListCB.blankIsNil;
    
    if(user.userName.isBlank || user.passWord.isBlank){
        [ODUAlerts showAlert:@"Missing Information" withDescription:@"Please Fill out both the user and password field"];
        return;
    }
    
    [[NSApp delegate] startProgressPanelWithMessage:@"Resetting password..." indeterminate:YES];
    ODUDirectoryConnection *service = [[ODUDirectoryConnection alloc]initConnection];
    [service resetPassword:user reply:^(NSError *error) {
            [[NSApp delegate] stopProgressPanel];
            if(error){
                [ODUAlerts showErrorAlert:error];
            }else{
                _passwordResetStatusTF.textColor = [NSColor blueColor];
                _passwordResetStatusTF.stringValue = [NSString stringWithFormat:@"Password reset for %@",user.userName];
            }
    }];
    
}

- (IBAction)choosePasswordResetFile:(id)sender{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:NO];
    
    [openPanel beginSheetModalForWindow:[[NSApplication sharedApplication]mainWindow] completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            _passwordResetFile.stringValue = [[openPanel URL] path];
        }
    }];
}

- (void)resetPasswordsFromFilePressed:(id)sender{
    NSError* error;
    
    if(!_dsServerStatusBT.state){
        error = [ODUError errorWithCode:ODUMNotAuthenticated];
        [ODUAlerts showErrorAlert:error];
        return;
    }
    
    if(_passwordResetFile.stringValue.isBlank){
        error = [ODUError errorWithCode:ODUMNoFileSelected];
        [ODUAlerts showErrorAlert:error];
        return;
    }
    
    ODUFileConnection *service = [[ODUFileConnection alloc]initConnection];
    service.inFile = _passwordResetFile.stringValue;
    service.userNameColumn = [[_userNameColumn stringValue] integerValue];
    service.passWordColumn = [[_passWordColumn stringValue] integerValue ];
    
    [[NSApp delegate] startProgressPanelWithMessage:@"Parsing file for passwords..." indeterminate:YES];

    [service makePasswordResetList:^(ODRecordList *records, NSError *error) {
        if(records.users.count > 0){
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [[[NSApp delegate] progressIndicator] setIndeterminate:NO];
            }];
            ODUDirectoryConnection *service = [[ODUDirectoryConnection alloc]initConnection];
            [service resetPasswords:records reply:^(NSError *error) {
                [[NSApp delegate] stopProgressPanel];
                if(error){
                    [ODUAlerts showErrorAlert:error];
                }
            }];
        }else{
            [[NSApp delegate] stopProgressPanel];
            [ODUAlerts showErrorAlert:error];
        }
    }];
}

#pragma mark - Other Panel
- (IBAction)deleteUserPressed:(id)sender {
    ODUDirectoryConnection *service = [[ODUDirectoryConnection alloc]initWithQueryDelegate:self];

    [service deleteUser:_deleteUserCB.stringValue reply:^(NSError *error) {
        if(error){
            [ODUAlerts showErrorAlert:error];
        }else{
            [ODUAlerts showAlert:@"Rremoved User" withFormattedMessage:@"We removed %@ from the Directory Server",_deleteUserCB.stringValue];
            [dsUserArrayController removeObjectAtArrangedObjectIndex:[_deleteUserCB indexOfSelectedItem]];
            _deleteUserCB.stringValue = @"";
        }
    }];
}

- (IBAction)modifyGroupPressed:(id)sender {
}

#pragma mark - Server Status IBActions
//-------------------------------------------
//  Server Status IBActions
//-------------------------------------------
-(IBAction)refreshServerStatus:(id)sender{
    if(_diradminPassTF.isBlank){
        if(![self getKeyChainPassword:nil]){
            [self didRecieveStatusUpdate:kODMNodeNotSet message:@""];
            return;
        }
    }
    
    ODUDirectoryConnection *service = [[ODUDirectoryConnection alloc]initWithAuthDelegate:self];
    
    [_dsServerStatusProgress startAnimation:nil];
    [_dsServerStatusProgress setHidden:NO];
    [_dsServerRefreshButtonBT setHidden:YES];
    
    [service checkServerStatus];
}


- (IBAction)editServerName:(id)sender{
    [self getKeyChainPassword:nil];
}

-(IBAction)getSettingsForPreset:(id)sender{
    ODUDirectoryConnection* service = [[ODUDirectoryConnection alloc]initWithQueryDelegate:self];
    [service getSettingsForPreset];
}



#pragma mark - Authenticator Delegate
//-------------------------------------------
//  Authenticator Delegate
//-------------------------------------------
-(void)didRecieveStatusUpdate:(OSStatus)status message:(NSString *)message{
    [_dsServerStatusProgress stopAnimation:nil];
    [_dsServerStatusProgress setHidden:YES];
    [_dsServerRefreshButtonBT setHidden:NO];
    
    if(status <= 0){
        [_dsServerStatusBT setImage:[NSImage imageNamed:@"connected-offline.tiff"]];
    }else{
        [self setKeyChainPassword];
        [ODUDirectoryConnection getUserList:self];
        [ODUDirectoryConnection getGroupList:self];
        [ODUDirectoryConnection getPresetList:self];
    }
    
    switch(status){
        case kODMNodeAuthenticatedLocal:
            [_dsServerStatusBT setImage:[NSImage imageNamed:@"connected-local.tiff"]];
            break;
        case kODMNodeAuthenticatedProxy:
            [_dsServerStatusBT setImage:[NSImage imageNamed:@"connected-proxy.tiff"]];
            break;
        default:
            [_dsServerStatusBT setImage:nil ];
            break;
            
    }
    _dsStatusMessageTF.stringValue = message;
}

-(void)didGetPassWordFromKeychain:(NSString *)password{
    _diradminPassTF.stringValue = password;
}

-(NSString *)nameOfDiradmin{
    return _diradminNameTF.blankIsNil;

}

-(NSString *)nameOfServer{
    return _serverNameTF.blankIsNil;
}

-(NSString *)passwordForDiradmin{
    return _diradminPassTF.blankIsNil;
}


#pragma mark - ODUDSQueryDelegate
//-------------------------------------------
//  Querier Delegate
//-------------------------------------------
-(void)didGetDSUserList:(NSArray *)dsusers{
    [dsUserArrayController setContent:dsusers];
}

-(void)didGetDSGroupList:(NSArray *)dsgroups{
    [dsGroupArrayController setContent:dsgroups];
    NSString* exg = [[NSUserDefaults standardUserDefaults]objectForKey:@"extraGroup"];
    _extraGroupShortNameCB.stringValue = exg.isNotBlank ? exg:@"staff";
}

-(void)didGetDSUserPresets:(NSArray *)dspresets{
    dsPresetArrayController.content = dspresets;
    _chooseUserPresetBT.title = dspresets.count ? dspresets[0]:@"Configure";
    _userPresetPUB.title = dspresets.count ? dspresets[0]:@"";
    ODUDirectoryConnection *service = [[ODUDirectoryConnection alloc]initWithQueryDelegate:self];
    [service getSettingsForPreset];
}

- (void)didGetUserRecord:(NSString*)user{
    [dsUserArrayController addObject:user];
}

-(void)didGetSettingsForPreset:(ODPreset *)preset{
    if(preset){
        _chooseUserPresetBT.title = preset.presetName.isNotBlank ? preset.presetName:@"Configure";
        _sharePointTF.stringValue = preset.sharePoint.isNotBlank ? preset.sharePoint:@"";
        _sharePathTF.stringValue  = preset.sharePath.isNotBlank  ? preset.sharePath:@"";
        _userShellTF.stringValue  = preset.userShell.isNotBlank  ? preset.userShell:@"/bin/csh";
        _NFSPathTF.stringValue    = preset.nfsPath.isNotBlank    ? preset.nfsPath:@"";
    }
}

-(NSString *)nameOfPreset{
    return _userPresetPUB.titleOfSelectedItem.blankIsNil;
}


#pragma mark - Keychain
//-------------------------------------------
//  KeyChanin
//-------------------------------------------
-(BOOL)getKeyChainPassword:(NSError*__autoreleasing*)error{
    NSString *serverName = _serverNameTF.blankIsNil;
    NSString *diradminName = _diradminNameTF.blankIsNil;
    
    NSString* kcAccount = [NSString stringWithFormat:@"%@:%@",diradminName ,serverName];
    NSString* kcPass = [SSKeychain passwordForService:
                        [[NSBundle mainBundle] bundleIdentifier] account:kcAccount error:error];
    
    if(kcPass){
        [self didGetPassWordFromKeychain:kcPass];
        return YES;
    }
    return NO;
}

-(void)setKeyChainPassword{
    if(_diradminPassTF.isNotBlank && _serverNameTF.isNotBlank){
        NSString* kcAccount = [NSString stringWithFormat:@"%@:%@",_diradminNameTF.stringValue,_serverNameTF.stringValue];
        
        [SSKeychain setPassword:_diradminPassTF.stringValue forService:[[NSBundle mainBundle] bundleIdentifier] account:kcAccount];
    }
}

#pragma mark - Sheets and Panels
//-------------------------------------------
//  Save Panel
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

-(IBAction)settingsDone:(id)sender{
    [_presetConfigSheet orderOut:self];
    [NSApp endSheet:_presetConfigSheet returnCode:0];
    
    if(_extraGroupDescriptionTF.isNotBlank){
        _extraGroupBT.title = _extraGroupDescriptionTF.stringValue;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:_extraGroupShortNameCB.stringValue forKey:@"extraGroup"];
}


@end

