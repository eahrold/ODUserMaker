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
#import "ODUserBridge.h"
#import "SSKeychain.h"
#import "ODUAlerts.h"
#import "ODUDSQuery.h"
#import "ODUStatus.h"

@implementation ODUController{
    NSMutableArray *groups;
}

#pragma mark -- Add Single User
-(void)makeSingleUserPressed:(id)sender{
    NSError* error = nil;
    
    if(!_dsServerStatus.state){
        error = [ODUserError errorWithCode:ODUMNotAuthenticated];
        [ODUAlerts showErrorAlert:error];
        return;
    }
    
    NSArray* requiredFields = [NSArray arrayWithObjects:_firstName,_lastName,_userName,_userCWID,_emailDomain,_defaultGroup, nil];
    
    for (NSTextField* i in requiredFields){
        if([i.stringValue isEqual: @""]){
            [ODUAlerts showAlert:@"Missing fileds" withDescription:@"Please fill out all fields"];
            return;
        }
    }
    
    /* Set up the User Object */
    User* user = nil;
    user = [User new];
    user.firstName = _firstName.stringValue;
    user.lastName = _lastName.stringValue;
    user.userName = _userName.stringValue;
    user.userCWID = _userCWID.stringValue;
    user.emailDomain = _emailDomain.stringValue;
    user.primaryGroup = _defaultGroup.stringValue;
    user.userPreset = [ _userPreset titleOfSelectedItem];
    user.userCount = [NSNumber numberWithInt:1];
    user.userShell = _userShell.stringValue;
    user.sharePath = _sharePath.stringValue;
    user.sharePoint = _sharePoint.stringValue;
    user.nfsPath = _NFSPath.stringValue;
    
    NSMutableArray* ug = [NSMutableArray new];
    
    if(_extraGroup.state){
        [ug addObject:_extraGroupShortName.stringValue];
    }
    
    //do get other groups...
    for (NSString* i in _groupEntries.itemTitles){
        [ug addObject:i];
    }
    //then...
    NSArray* userGroups = [NSArray arrayWithArray:ug];
    
    if(_overrideUID.state){
        NSNumberFormatter* f = [NSNumberFormatter new];
        if([f numberFromString:_uuid.stringValue]){
            user.userUUID = _uuid.stringValue;
        }else{
            [ODUAlerts showAlert:@"The UID Is not Usable" withDescription:@"The UID you specifiied is not a number.  Please check it and try again"];
            return;
        }
    }
    
    if(_extraGroup.state){
        user.keyWord = _extraGroupDescription.stringValue;
    }
    
    [ODUDSQuery addUser:user toGroups:userGroups sender:self];
}

-(IBAction)addGroupToUser:(id)sender{
    [_groupEntries insertItemWithTitle:[_serverGroupListSingleUser titleOfSelectedItem] atIndex:0];
    [_groupEntries selectItemAtIndex:0];
}

-(IBAction)removeGroupFromUser:(id)sender{
    if( _groupEntries.indexOfSelectedItem > -1){
        [_groupEntries removeItemAtIndex:[_groupEntries indexOfSelectedItem]];
    }
}

-(IBAction)overrideUUID:(id)sender{
    if([_overrideUID state]){
        [_uuid setHidden:FALSE];
    }else{
        [_uuid setHidden:TRUE];
        [_uuid setStringValue:@""];
    }
}



#pragma mark -- Add Users using File
- (IBAction)makeMultiUserPressed:(id)sender{
    NSButton* button = sender;
    
    NSError* error = nil;
    if(!_dsServerStatus.state){
        error = [ODUserError errorWithCode:ODUMNotAuthenticated];
        [ODUAlerts showErrorAlert:error];
        return;
    }
    
    /*set up the user object*/
    User* user = [User new];
    user.emailDomain = _emailDomain.stringValue;
    user.primaryGroup = _defaultGroup.stringValue;
    user.userPreset = [ _userPreset titleOfSelectedItem];
    user.keyWord = @"";
    
    if(![_userFilter.stringValue isEqualToString:@""]){
        user.userFilter = _userFilter.stringValue;
    }else{
        user.userFilter = @" ";
    }
    
    /* Set up the import FileHandles */
    NSURL * importFileURL = [NSURL fileURLWithPath:_importFilePath.stringValue];
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

-(IBAction)addGroupMatch:(id)sender{
    NSString* match = [_fileClassList stringValue];
    NSString* group = [_serverGroupList titleOfSelectedItem];
    
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
    if(_groupMatchEntries.indexOfSelectedItem > -1){
        [groups removeObjectAtIndex:[_groupMatchEntries indexOfSelectedItem]];
        [groupMatchArrayController setContent:groups];
    }
}

-(IBAction)cancelUserImport:(id)sender{
    [ODUDSQuery cancelUserImport:self];
}

#pragma mark -- Reset Password
- (IBAction)resetPasswordPressed:(id)sender{
    NSError* error = nil;
    
    if(!_dsServerStatus.state){
        error = [ODUserError errorWithCode:ODUMNotAuthenticated];
        [ODUAlerts showErrorAlert:error];
        return;
    }
    /* Set up the User Object */
    User* user = [User new];
    user.userName = [_userList stringValue];
    user.userCWID = [_passWord stringValue];
    
    if([user.userName isEqualToString:@""]){
        [ODUAlerts showAlert:@"Name feild empty" withDescription:@"The name field can't be empty"];
        return;
    }
    
    if([user.userCWID isEqualToString:@""]){
        [ODUAlerts showAlert:@"New Password Feild Empty" withDescription:@"The password field can't be empty"];
        return;
    }
    
    [self startProgressPanelWithMessage:@"Resetting password..." indeterminate:YES];
    _statusUpdate.stringValue = @"";
    [ODUDSQuery resetPassword:user sender:self];
}


-(IBAction)getSettingsForPreset:(id)sender{
    NSString* preset = _userPreset.titleOfSelectedItem;
    if(![preset isEqualToString:@""]){
        [ODUDSQuery getSettingsForPreset:preset sender:self];
    }
}

#pragma mark -- Server Status
-(IBAction)refreshServerStatus:(id)sender{
    NSError* error;
    if([_serverName.stringValue   isEqualToString:@""]||
       [_diradminName.stringValue isEqualToString:@""]||
       [_diradminPass.stringValue isEqualToString:@""]){
        return;
    }
    
    Server* server = [Server new];
    server.serverName = _serverName.stringValue;
    server.diradminName = _diradminName.stringValue;
    server.diradminPass = _diradminPass.stringValue;
    
    [_dsServerStatusProgress startAnimation:nil];
    [_dsServerStatusProgress setHidden:NO];
    [_dsServerRefreshButton setHidden:YES];
    
    [[ODUStatus sharedStatus] addObserver:self
                               forKeyPath:@"serverStatus"
                                  options:NSKeyValueObservingOptionNew
                                  context:NULL];
    
    [ODUDSQuery getAuthenticatedDirectoryNode:server error:&error];
    
    if(error){
        [_dsServerStatusProgress stopAnimation:nil];
        [_dsServerStatusProgress setHidden:YES];
        [_dsServerRefreshButton setHidden:NO];
        [[ODUStatus sharedStatus]removeObserver:self forKeyPath:@"serverStatus"];
        [ ODUAlerts showErrorAlert:error];
    }
}


-(void)setServerStatus:(OSStatus)status{
    
    [_dsServerStatusProgress stopAnimation:nil];
    [_dsServerStatusProgress setHidden:YES];
    [_dsServerRefreshButton setHidden:NO];

    if(status < 0){
        [_dsServerStatus setImage:[NSImage imageNamed:@"connected-offline.tiff"]];
    }else{
        [self setKeyChainPassword];
        [self setAllObservers];
        
        [ODUDSQuery getDSUserPresets];
        [ODUDSQuery getDSGroupList];
        [ODUDSQuery getDSUserList];
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
            [_dsServerStatus setImage:[NSImage imageNamed:@"connected-local.tiff"]];
            break;
        case ODUAuthenticatedProxy  : sv = @"The the username and password are correct, connected over proxy";
            [_dsServerStatus setImage:[NSImage imageNamed:@"connected-proxy.tiff"]];
            break;
        default: sv = @""; [_dsServerStatus setImage:nil ];break;
            
    }

    _dsStatusMessage.stringValue = sv;
}



- (IBAction)editServerName:(id)sender{
        if([self getKeyChainPassword])[self refreshServerStatus:nil];
}

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

-(IBAction)chooseImportFile:(id)sender{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:NO];
    
    [openPanel beginSheetModalForWindow:[[NSApplication sharedApplication]mainWindow] completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            _importFilePath.stringValue = [openPanel URL].path;
        }
    }];
    
}

#pragma mark -- Keychains
//-------------------------------------------
//  Keychain Methods
//-------------------------------------------
-(BOOL)getKeyChainPassword{
    NSError* error;
    NSString* kcAccount = [NSString stringWithFormat:@"%@:%@",_diradminName.stringValue,_serverName.stringValue];
    NSString* kcPass = [SSKeychain passwordForService:
                           [[NSBundle mainBundle] bundleIdentifier] account:kcAccount error:&error];
    
    if(kcPass)_diradminPass.stringValue=kcPass;
    if(error)return NO;
    return YES;
}

-(void)setKeyChainPassword{
    if(![_diradminPass.stringValue isEqualToString:@""]){
        NSString* kcAccount = [NSString stringWithFormat:@"%@:%@",_diradminName.stringValue,_serverName.stringValue];
        [SSKeychain setPassword:_diradminPass.stringValue forService:[[NSBundle mainBundle] bundleIdentifier] account:kcAccount];
    }
}

#pragma mark -- Sheets and Panels
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
    
    if(![_extraGroupDescription.stringValue isEqualToString:@""]){
        _extraGroup.title = _extraGroupDescription.stringValue;
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
    [self.progressCancelButton setEnabled:YES];
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


- (void)addUserToUserList:(NSString*)user{
    [dsUserArrayController addObject:user];
}


#pragma mark -- Observers
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if([keyPath isEqualToString:@"userList"]){
        [dsUserArrayController setContent:[object valueForKeyPath:keyPath]];
        [[ODUStatus sharedStatus] removeObserver:self forKeyPath:keyPath];
    }
    else  if([keyPath isEqualToString:@"groupList"]){
        [dsGroupArrayController setContent:[object valueForKeyPath:keyPath]];
        [[ODUStatus sharedStatus] removeObserver:self forKeyPath:keyPath];
    }
    else if([keyPath isEqualToString:@"presetList"]){
        [dsPresetArrayController setContent:[object valueForKeyPath:keyPath]];
        [[ODUStatus sharedStatus] removeObserver:self forKeyPath:keyPath];
    }
    else if ([keyPath isEqualToString:@"serverStatus"]){
        [self setServerStatus:[[object valueForKeyPath:keyPath]intValue]];
        [[ODUStatus sharedStatus] removeObserver:self forKeyPath:keyPath];
    }
}

-(void)setAllObservers{
    [[ODUStatus sharedStatus] addObserver:self forKeyPath:@"userList" options:NSKeyValueObservingOptionNew context:NULL];
    [[ODUStatus sharedStatus] addObserver:self forKeyPath:@"groupList" options:NSKeyValueObservingOptionNew context:NULL];
    [[ODUStatus sharedStatus] addObserver:self forKeyPath:@"presetList" options:NSKeyValueObservingOptionNew context:NULL];
}

-(void)awakeFromNib{
    [_dsServerStatusProgress startAnimation:nil];
    [_dsServerRefreshButton setHidden:YES];
    
    [[ODUStatus sharedStatus] addObserver:self forKeyPath:@"serverStatus" options:NSKeyValueObservingOptionNew context:NULL];
    [[ODUStatus sharedStatus] addObserver:self forKeyPath:@"userList" options:NSKeyValueObservingOptionNew context:NULL];
    [[ODUStatus sharedStatus] addObserver:self forKeyPath:@"groupList" options:NSKeyValueObservingOptionNew context:NULL];
    [[ODUStatus sharedStatus] addObserver:self forKeyPath:@"presetList" options:NSKeyValueObservingOptionNew context:NULL];
}
@end
