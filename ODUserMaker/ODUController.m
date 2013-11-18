//
//  AppController.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUController.h"
#import "FileService.h"
#import "OpenDirectoryService.h"
#import "ODCommonHeaders.h"
#import "ODUDSQuery.h"
#import "ODUPasswordReset.h"

@implementation ODUController{
    NSMutableArray *groups;
}
@synthesize authenticator;


-(void)awakeFromNib{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshServerStatus:)
                                                 name:@"appLaunched"
                                               object:nil];
    
}


#pragma mark -- Add Single User
-(void)makeSingleUserPressed:(id)sender{
    NSError* error = nil;
    
    if(!_dsServerStatusBT.state){
        error = [ODUserError errorWithCode:ODUMNotAuthenticated];
        [ODUAlerts showErrorAlert:error];
        return;
    }
    
    NSArray* requiredFields = [NSArray arrayWithObjects:_firstNameTF,_lastNameTF,_userNameTF,_userCWIDTF,_emailDomainTF,_defaultGroupTF, nil];
    
    for (NSTextField* i in requiredFields){
        if([i.stringValue isEqual: @""]){
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
        [ug addObject:_extraGroupShortNameCB.stringValue];
    }
    
    //do get other groups...
    for (NSString* i in _groupEntriesPUB.itemTitles){
        [ug addObject:i];
    }
    //then...
    NSArray* userGroups = [NSArray arrayWithArray:ug];
    
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
    
    [ODUDSQuery addUser:user toGroups:userGroups sender:self];
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



#pragma mark -- Add Users using File
- (IBAction)makeMultiUserPressed:(id)sender{
    NSButton* button = sender;
    
    NSError* error = nil;
    if(!_dsServerStatusBT.state){
        error = [ODUserError errorWithCode:ODUMNotAuthenticated];
        [ODUAlerts showErrorAlert:error];
        return;
    }
    
    /*set up the user object*/
    User* user = [User new];
    user.emailDomain = _emailDomainTF.stringValue;
    user.primaryGroup = _defaultGroupTF.stringValue;
    user.userPreset = [ _userPresetPUB titleOfSelectedItem];
    user.keyWord = @"";
    
    if(![_userFilterTF.stringValue isEqualToString:@""]){
        user.userFilter = _userFilterTF.stringValue;
    }else{
        user.userFilter = @" ";
    }
    
    /* Set up the import FileHandles */
    NSURL * importFileURL = [NSURL fileURLWithPath:_importFilePathTF.stringValue];
    user.importFileHandle = [NSFileHandle fileHandleForReadingFromURL:importFileURL error:&error];
    
    if([button.title isEqualToString:@"Import Users"]){
        [ODUDSQuery addUserList:user withGroups:groups sender:self];
        return;
    }
    
    if([button.title isEqualToString:@"Make DSImport File"]){
        NSURL* exportFileURL =[self openSavePanel];
        
        if(!exportFileURL){
            error = [ODUserError errorWithCode:ODUMWriteFileError];
            [ODUAlerts showErrorAlert:error];
            return;
        }
        
        [[NSData data] writeToURL:exportFileURL options:0 error:&error];
        if(error){
            [ODUAlerts showErrorAlert:error];
            return;
        }

        [self startProgressPanelWithMessage:@"Creating DSImport File..." indeterminate:YES];
        user.exportFile = [NSFileHandle fileHandleForWritingToURL:exportFileURL error:&error];
        [ODUDSQuery addUserList:user withGroups:groups sender:self];
    }
}

-(IBAction)cancelUserImport:(id)sender{
    [ODUDSQuery cancelUserImport:self];
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
    NSString* match = _classListFileTF.stringValue;
    NSString* group = [_serverGroupListPUB titleOfSelectedItem];
    
    if(!groups){
        groups = [[NSMutableArray alloc] init];
    }
    
    if([group isEqualToString:@""]||[match isEqualToString:@""])
        return;
    
    NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@:%@",group,match],@"description",group, @"group", match, @"match", nil];

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


#pragma mark -- Reset Password
- (IBAction)resetPasswordPressed:(id)sender{
    NSError* error = nil;
    
    if(!_dsServerStatusBT.state){
        error = [ODUserError errorWithCode:ODUMNotAuthenticated];
        [ODUAlerts showErrorAlert:error];
        return;
    }
    
    ODUPasswordReset* resetter = [ODUPasswordReset new];
    resetter.userName = _userListCB.stringValue;
    resetter.NewPassword = _NewPassWordTF.stringValue;
    [resetter resetPassword:self];
}




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
    if(!_querier){
        _querier = [[ODUDSQuery alloc]initWithDelegate:self];
    }
    
    [_querier getSettingsForPreset];
}



#pragma mark -- Authenticator Delegate
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
        if(!_querier){
            _querier = [[ODUDSQuery alloc]initWithDelegate:self];
        }
        [_querier getDSUserPresets];
        [_querier getDSUserList];
        [_querier getDSGroupList];
    }
    
    NSString* sv;
    switch(status){
        case ODUNoNode: sv = @"Could Not Contact Server";
            break;
        case ODUUnauthenticatedLocal: sv = @"Could Not Authenticate to Local Directory Server";
            break;
        case ODUUnauthenticatedProxy: sv = @"Could Not Authenticate to Directory Server Remotley";
            break;
        case ODUAuthenticatedLocal  : sv = @"The the username and password are correct, connected locally.";
            [_dsServerStatusBT setImage:[NSImage imageNamed:@"connected-local.tiff"]];
            break;
        case ODUAuthenticatedProxy  : sv = @"The the username and password are correct, connected over proxy";
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
    if([_diradminNameTF.stringValue isEqualToString:@""])return nil;
    return _diradminNameTF.stringValue;

}

-(NSString *)nameOfServer:(ODUAuthenticator *)authenticator{
    if([_serverNameTF.stringValue isEqualToString:@""])return nil;
    return _serverNameTF.stringValue;
}

-(NSString *)passwordForDiradmin:(ODUAuthenticator *)authenticator{
    if([_diradminPassTF.stringValue isEqualToString:@""])return nil;
    return _diradminPassTF.stringValue;
}


#pragma mark -- ODUDSQueryDelegate
//-------------------------------------------
//  Querier Delegate
//-------------------------------------------
-(void)didGetDSGroupList:(NSArray *)dsgroups{
    [dsGroupArrayController setContent:dsgroups];
}

-(void)didGetDSUserList:(NSArray *)dsusers{
    [dsUserArrayController setContent:dsusers];
}

-(void)didGetDSUserPresets:(NSArray *)dspresets{
    [dsPresetArrayController setContent:dspresets];
}

-(void)didGetSettingsForPreset:(NSDictionary *)settings{
    _sharePointTF.stringValue = settings[@"sharePoint"];
    _sharePathTF.stringValue  = settings[@"sharePath"];
    _userShellTF.stringValue  = settings[@"userShell"];
    _NFSPathTF.stringValue    = settings[@"NFSHome"];
}

-(NSString *)nameOfPreset{
    if([_userPresetPUB.titleOfSelectedItem isEqualToString:@""])return nil;
    return _userPresetPUB.titleOfSelectedItem;
}



#pragma mark -- Sheets and Panels
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
}

//-------------------------------------------
//  Progress Panel
//-------------------------------------------

- (void)startProgressPanelWithMessage:(NSString*)message indeterminate:(BOOL)indeterminate {
    /* Display a progress panel as a sheet */
    self.progressMessage = message;
    
    if (indeterminate) {
        [self.progressIndicator setIndeterminate:YES];
        [self.progressIndicator displayIfNeeded];
    } else {
        [self.progressIndicator setUsesThreadedAnimation:YES];
        [self.progressIndicator setIndeterminate:NO];
        [self.progressIndicator setDoubleValue:0.0];
        [self.progressIndicator displayIfNeeded];
    }
    
    [self.progressIndicator startAnimation:self];
    [self.progressCancelButtonBT setEnabled:YES];
    [NSApp beginSheet:self.progressPanel
       modalForWindow:[[NSApplication sharedApplication]mainWindow]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:NULL];
}

- (void)stopProgressPanel {
    [self.progressPanel orderOut:self];
    [NSApp endSheet:self.progressPanel returnCode:0];
}



#pragma mark -- NSXPC exported object Protocol
//----------------------------------------------------
//  NSXPC Return Messages via Exported Object Protocol
//----------------------------------------------------
- (void)setProgressMsg:(NSString*)message{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       self.progressMessage = message;
    }];
}

- (void)setProgress:(double)progress withMessage:(NSString*)message {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.progressIndicator incrementBy:progress];
        self.progressMessage = message;
    }];
}

- (void)setProgress:(double)progress {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.progressIndicator incrementBy:progress];
    }];
}



@end
