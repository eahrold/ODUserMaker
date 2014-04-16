//
//  AppController.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUController.h"
#import "ODUDelegate.h"
#import "ODUFileParser.h"
#import "ODUAlerts.h"
#import "SSKeychain.h"
#import "NSString(TextField)+isNotBlank.h"
#import <ODManger/ODManager.h>


@interface ODUController ()<ODManagerDelegate>
@property (strong)  ODManager *manager;
@end

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

    [[NSApp delegate] startProgressPanelWithMessage:@"Adding Users..." indeterminate:YES];

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
    
    [_manager addUser:user error:&error];
    [[NSApp delegate] stopProgressPanel];
    if(error.code == kODMerrUserAlreadyExists){
        [ODUAlerts showErrorAlert:error];
        return;
    }else{
        for(NSString* group in ug){
            [_manager addUser:user.userName toGroup:group error:nil];
        }
    }
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
    
    ODUFileParser* fs = [ODUFileParser new];
    
    [[[NSApp delegate] progressIndicator] setIndeterminate:YES];
    [[[NSApp delegate] progressIndicator] setUsesThreadedAnimation:YES];
    
    /*before we send the groups array off arrange the order*/
    [_groups sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"group"
                                                                  ascending:YES]]];
    
    if([sender.title isEqualToString:@"Import Users"]){
        [[NSApp delegate] startProgressPanelWithMessage:@"Importing Users..." indeterminate:YES];
        [fs makeUserArray:user importFile:_importFilePathTF.blankIsNil exportFile:nil filter: _userFilterTF.stringValue andGroupList:_groups withReply:^(NSArray *groupList, ODRecordList *userlist, NSError *fileParseError){
            if(fileParseError){
                [[NSApp delegate] stopProgressPanel];
                [ODUAlerts showErrorAlert:fileParseError];
            }
            else{
            [_manager addListOfUsers:userlist withPreset:nil reply:^(NSError *userImportError){
                for(NSDictionary* group in groupList){
                    NSString *groupName = group[@"group"];
                    NSArray  *users = group[@"users"];
                    [[ODManager sharedManager] addUsers:users toGroup:groupName error:nil];
                    }
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [[NSApp delegate] stopProgressPanel];
                    if(userImportError){
                        [ODUAlerts showErrorAlert:userImportError];
                    }else{
                        [ODUAlerts showAlert:@"Import Complete" withDescription:@""];
                    }
                }];
            }];
            }
        }];
    }
    else if([sender.title isEqualToString:@"Make DSImport File"]){
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
        
        NSFileHandle *outFile = [NSFileHandle fileHandleForWritingToURL:exportFileURL error:&error];
        
        if(error){
            [ODUAlerts showErrorAlert:error];
            return;
        }
        [[NSApp delegate] startProgressPanelWithMessage:@"Creating DSImport File..." indeterminate:YES];
        [fs makeMultiUserFile:user importFile:_importFilePathTF.stringValue exportFile:outFile filter:_userFilterTF.stringValue withReply:^(NSError *error) {
            [[NSApp delegate] stopProgressPanel];
            if(error){
                [ODUAlerts showErrorAlert:error];
            }
        }];
    }
}

-(IBAction)cancelUserImport:(id)sender{
    [_manager cancelUserImport];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSApp delegate]stopProgressPanel];
    }];
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
    
    NSString *userName = _userListCB.blankIsNil;
    NSString *passWord = _NewPassWordTF.blankIsNil;
    
    if(!userName || !passWord){
        [ODUAlerts showAlert:@"Missing Information" withDescription:@"Please Fill out both the user and password field"];
        return;
    }
    
    [[NSApp delegate] startProgressPanelWithMessage:@"Resetting password..." indeterminate:YES];
    
    ODManager *manger = [ODManager sharedManager];

    [manger resetPassword:nil
               toPassword:passWord
                     user:userName
                    error:&error];
    
    
    [[NSApp delegate] stopProgressPanel];
    if(error){
        [ODUAlerts showErrorAlert:error];
    }else{
        _passwordResetStatusTF.textColor = [NSColor blueColor];
        _passwordResetStatusTF.stringValue = [NSString stringWithFormat:@"Password reset for %@",userName];
    }
    
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
    
    NSInteger userColumn = [[_userNameColumn stringValue] integerValue];
    NSInteger passColumn = [[_passWordColumn stringValue] integerValue ];
    
    [[NSApp delegate] startProgressPanelWithMessage:@"Parsing file for passwords..." indeterminate:YES];
    
    ODUFileParser *parser = [ODUFileParser new];
    NSOperationQueue *background = [NSOperationQueue new];
    [background addOperationWithBlock:^{
        [parser makePasswordResetListFromFile:_passwordResetFile.stringValue usernameColumn:userColumn passwordColumn:passColumn reply:^(ODRecordList *records, NSError *error) {
            if(records.users.count > 0){
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [[[NSApp delegate] progressIndicator] setIndeterminate:NO];
                }];
                double progress = 0.0;
                for(ODUser *user in records.users){
                    progress++;
                    [_manager resetPassword:nil toPassword:user.passWord user:user.userName];
                    NSString *msg = [NSString stringWithFormat:@"resetting password for %@",user.userName];

                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [[NSApp delegate] setProgress:(progress/records.users.count*100) withMessage:msg];
                    }];
                }
                
            }
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [[NSApp delegate] stopProgressPanel];
            }];
        }];
    }];
   
}

#pragma mark - Other Panel
- (IBAction)deleteUserPressed:(id)sender {
    NSLog(@"Removing User:");
    [_manager removeUsers:@[_deleteUserCB.stringValue] reply:^(NSError *error) {
        if(error){
            [ODUAlerts showErrorAlert:error];
        }else{
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [ODUAlerts showAlert:@"Rremoved User" withFormattedMessage:@"We removed %@ from the Directory Server",_deleteUserCB.stringValue];
                [dsUserArrayController removeObjectAtArrangedObjectIndex:[_deleteUserCB indexOfSelectedItem]];
                _deleteUserCB.stringValue = @"";
            }];
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
            [self didRecieveStatusUpdate:kODMNodeNotSet];
            return;
        }
    }

    _manager = [ODManager sharedManager];
    _manager.delegate = self;
    
    _manager.directoryServer  = _serverNameTF.stringValue;
    _manager.diradmin         = _diradminNameTF.stringValue;
    _manager.diradminPassword = _diradminPassTF.stringValue;

    [_dsServerStatusProgress startAnimation:nil];
    [_dsServerStatusProgress setHidden:NO];
    [_dsServerRefreshButtonBT setHidden:YES];
    
    [_manager authenticate];
    
}


- (IBAction)editServerName:(id)sender{
    [self getKeyChainPassword:nil];
}

-(IBAction)getSettingsForPreset:(id)sender{
    NSString *presetName;
    if([sender isKindOfClass:[NSPopUpButton class]] ){
        presetName = [[(NSPopUpButton*)sender titleOfSelectedItem] blankIsNil];
    }else if ([sender isKindOfClass:[NSString class]]){
        presetName = (NSString*)sender;
    }
              
    ODPreset *preset = [_manager settingsForPreset: presetName];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if(preset){
            _chooseUserPresetBT.title = preset.presetName.isNotBlank ? preset.presetName:@"Configure";
            _sharePointTF.stringValue = preset.sharePoint.isNotBlank ? preset.sharePoint:@"";
            _sharePathTF.stringValue  = preset.sharePath.isNotBlank  ? preset.sharePath:@"";
            _userShellTF.stringValue  = preset.userShell.isNotBlank  ? preset.userShell:@"/bin/csh";
            _NFSPathTF.stringValue    = preset.nfsPath.isNotBlank    ? preset.nfsPath:@"";
        }
    }];
}



#pragma mark - Authenticator Delegate
//-------------------------------------------
//  Authenticator Delegate
//-------------------------------------------
-(void)didRecieveStatusUpdate:(OSStatus)status{
    [[NSOperationQueue mainQueue]addOperationWithBlock:^{
        NSString* message = nodeStatusDescription(status);
        [_dsServerStatusProgress stopAnimation:nil];
        [_dsServerStatusProgress setHidden:YES];
        [_dsServerRefreshButtonBT setHidden:NO];
        
        if(status <= 0){
            [_dsServerStatusBT setImage:[NSImage imageNamed:@"connected-offline.tiff"]];
        }else{
            [self setKeyChainPassword];
            [self updateRecordArrays];
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
    }];
}


-(void)didGetPassWordFromKeychain:(NSString *)password{
    _diradminPassTF.stringValue = password;
}

-(void)updateRecordArrays{
    [_manager userList:^(NSArray *allUsers) {
        [[NSOperationQueue mainQueue]addOperationWithBlock:^{
            [dsUserArrayController setContent:allUsers];
        }];
    }];
    
    [_manager groupList:^(NSArray *allGroups) {
        [[NSOperationQueue mainQueue]addOperationWithBlock:^{
            [dsGroupArrayController setContent:allGroups];
            NSString* exg = [[NSUserDefaults standardUserDefaults]objectForKey:@"extraGroup"];
            _extraGroupShortNameCB.stringValue = exg.isNotBlank ? exg:@"staff";
        }];
    }];
    
    [_manager presetList:^(NSArray *allPresets) {
        [[NSOperationQueue mainQueue]addOperationWithBlock:^{
            [dsPresetArrayController setContent:allPresets];
            _chooseUserPresetBT.title = allPresets.count ? allPresets[0]:@"Configure";
            _userPresetPUB.title = allPresets.count ? allPresets[0]:@"";
            if(allPresets.count){
                [self getSettingsForPreset:allPresets[0]];
            }
        }];
    }];
}

#pragma mark - ODUDSQueryDelegate

-(void)didAddRecord:(NSString *)record progress:(double)progress{
    NSString *msg = [NSString stringWithFormat:@"added user %@",record];
    [[NSApp delegate]setProgress:progress withMessage:msg];
}

-(void)didAddUser:(NSString *)user toGroup:(NSString *)group progress:(double)progress{
    NSString *msg = [NSString stringWithFormat:@"updating %@, added user %@",group ,user];
    [[NSApp delegate]setProgress:progress withMessage:msg];
}

//-------------------------------------------
//  Querier Delegate
//-------------------------------------------

-(void)didRecieveQueryUpdate:(id)record{
    [[NSOperationQueue mainQueue]addOperationWithBlock:^{
        if([record isKindOfClass:[ODUser class]]){
            [dsUserArrayController addObject:[(ODUser*)record userName]];
        }
        else if ([record isKindOfClass:[ODGroup class]]){
            [dsGroupArrayController addObject:[(ODGroup*)record groupName]];
        }
        else if ([record isKindOfClass:[ODPreset class]]){
            [dsPresetArrayController addObject:[(ODPreset*)record presetName]];
        }
    }];
}


- (void)didGetUserRecord:(NSString*)user{
    [dsUserArrayController addObject:user];
}

-(void)didGetSettingsForPreset:(ODPreset *)preset{
    [[NSOperationQueue mainQueue]addOperationWithBlock:^{
        if(preset){
            _chooseUserPresetBT.title = preset.presetName.isNotBlank ? preset.presetName:@"Configure";
            _sharePointTF.stringValue = preset.sharePoint.isNotBlank ? preset.sharePoint:@"";
            _sharePathTF.stringValue  = preset.sharePath.isNotBlank  ? preset.sharePath:@"";
            _userShellTF.stringValue  = preset.userShell.isNotBlank  ? preset.userShell:@"/bin/csh";
            _NFSPathTF.stringValue    = preset.nfsPath.isNotBlank    ? preset.nfsPath:@"";
        }
    }];
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

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
}


@end

