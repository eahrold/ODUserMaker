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
    
    NSString* progress = [NSString stringWithFormat:@"adding %@ to %@...", user.userName, _serverName.stringValue];
    [self startProgressPanelWithMessage:progress indeterminate:YES];
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] addSingleUser:user andGroups:userGroups withReply:^(NSError *error){
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self stopProgressPanel];
            if(error){
                NSLog(@"Error: %@",[error localizedDescription]);
                [ODUAlerts showErrorAlert:error];
            }else{
                _statusUpdateUser.stringValue = [NSString stringWithFormat:@"Added/Updated %@",user.userName];
            }
        }];
        [connection invalidate];
    }];

}

- (IBAction)makeMultiUserPressed:(id)sender{
    NSError* error = nil;
    if(!_dsServerStatus.state){
        error = [ODUserError errorWithCode:ODUMNotAuthenticated];
        [self showErrorAlert:error];
        return;
    }
    
    [self startProgressPanelWithMessage:@"Adding List of Users..." indeterminate:YES];
    
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
    
    /* Set up the import and export FileHandles */
    NSURL * importFileURL = [NSURL fileURLWithPath:_importFilePath.stringValue];
    user.importFileHandle = [NSFileHandle fileHandleForReadingFromURL:importFileURL error:&error];
    
    NSString* timeStamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
    NSURL* exportFile = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(),timeStamp]];
    user.exportFile = [NSFileHandle fileHandleForWritingToURL:exportFile error:&error];
    
    /* we've got to touch the file befor creating the file handle */
    if (![[NSData data] writeToURL:exportFile options:0 error:&error]) {
        [self stopProgressPanel];
        [self showErrorAlert:error];
        return;
    }
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kFileServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(FileService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] makeUserArray:user andGroupList:groups withReply:^(NSArray* dsgroups,NSArray* userlist, NSError* error){
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(error){
                [self stopProgressPanel];
                [self showErrorAlert:error];
            }else{
                NSString* progress = [NSString stringWithFormat:@"adding %lu users to %@...", (unsigned long)[userlist count], _serverName.stringValue];
                [self startProgressPanelWithMessage:progress indeterminate:NO];
                
                NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
                connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
                connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
                connection.exportedObject = self;
                
                [connection resume];
                [[connection remoteObjectProxy] addListOfUsers:userlist usingPresetsIn:user andGroups:dsgroups withReply:^(NSError *error) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self stopProgressPanel];
                        if(error){
                            NSLog(@"Error: %@",[error localizedDescription]);
                            [self showErrorAlert:error];
                        }else{
                            //[self uploadUserList:user toServer:server];
                        }
                    }];
                    [connection invalidate];
                }];
            }
        }];
        [connection invalidate];
    }];
;
}

- (IBAction)resetPasswordPressed:(id)sender{
    NSError* error = nil;
    
    if(!_dsServerStatus.state){
        error = [ODUserError errorWithCode:ODUMNotAuthenticated];
        [self showErrorAlert:error];
        return;
    }
    /* Set up the User Object */
    User* user = [User new];
    user.userName = [_userList stringValue];
    user.userCWID = [_passWord stringValue];
    
    if([user.userName isEqualToString:@""]){
        [self showAlert:@"Name feild empty" withDescription:@"The name field can't be empty"];
        return;
    }
    
    if([user.userCWID isEqualToString:@""]){
        [self showAlert:@"New Password Feild Empty" withDescription:@"The password field can't be empty"];
        return;
    }
    
    /* Set up the Serve Object */
    Server* server = [Server new];
    server.serverName = _serverName.stringValue;
    server.diradminName = _diradminName.stringValue;
    server.diradminPass = _diradminPass.stringValue;
    
    [self startProgressPanelWithMessage:@"Resetting password..." indeterminate:YES];

    _statusUpdate.stringValue = @"";
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] resetUserPassword:user withReply:^(NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self stopProgressPanel];
            if(error){
                NSLog(@"Error: %@",[error localizedDescription]);
                [self showErrorAlert:error];
            }else{
                _statusUpdate.textColor = [NSColor redColor];
                _statusUpdate.stringValue = [NSString stringWithFormat:@"Password reset for %@",user.userName];
            }
        }];
        [connection invalidate];
    }];
}

-(IBAction)getSettingsForPreset:(id)sender{
    NSString* preset = _userPreset.titleOfSelectedItem;
    if([preset isEqualToString:@""])return;
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] getSettingsForPreset:preset withReply:^(NSDictionary *settings, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(!error){
                _sharePoint.stringValue = [settings valueForKey:@"sharePoint"];
                _sharePath.stringValue = [settings valueForKey:@"sharePath"];
                _userShell.stringValue = [settings valueForKey:@"userShell"];
                _NFSPath.stringValue = [settings valueForKey:@"NFSHome"];
            }
        }];
        [connection invalidate];
    }];

}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if([keyPath isEqualToString:@"userList"]){
        [dsUserArrayController setContent:[object valueForKeyPath:keyPath]];
    }
    else  if([keyPath isEqualToString:@"groupList"]){
        [dsGroupArrayController setContent:[object valueForKeyPath:keyPath]];
    }
    else if([keyPath isEqualToString:@"presetList"]){
        [dsPresetArrayController setContent:[object valueForKeyPath:keyPath]];

    }
    else if ([keyPath isEqualToString:@"serverStatus"]){
        // here are the status returns
        // -1 No Node
        // -2 locally connected, but wrong password
        // -3 proxy but wrong auth password
        // 0 Authenticated locally
        // 1 Authenticated over proxy

        OSStatus status = [[object valueForKeyPath:keyPath]intValue];
        
        if(status < 0){
            [_dsServerStatus setImage:[NSImage imageNamed:@"connected-offline.tiff"]];
            NSLog(@"Offline");
        }else{
            NSLog(@"OnLine");
            [ODUDSQuery getDSUserPresets];
            [ODUDSQuery getDSGroupList];
            [ODUDSQuery getDSUserList];
        }
        
        if(status == -1){
            _dsStatusMessage.stringValue = @"Could Not Connect to Remote Node";
        }else if (status == -2){
            _dsStatusMessage.stringValue = @"Locally connected, but username or password are incorrect";
        }else if (status == -3){
            _dsStatusMessage.stringValue = @"Could Not Connect to proxy server.";
        }else if (status == 0){
            _dsStatusMessage.stringValue = @"The the username and password are correct, connected locally.";
            [_dsServerStatus setImage:[NSImage imageNamed:@"connected-local.tiff"]];
                   }else if (status == 1){
            [_dsServerStatus setState:YES];
            _dsStatusMessage.stringValue = @"The the username and password are correct, connected over proxy";
            [_dsServerStatus setImage:[NSImage imageNamed:@"connected-proxy.tiff"]];
        }
    }
}

//-------------------------------------------
//  Progress Panel and Alert
//-------------------------------------------

- (void)showErrorAlert:(NSError *)error {
    [[NSAlert alertWithError:error] beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow]
                                               modalDelegate:self
                                              didEndSelector:NULL
                                                 contextInfo:NULL];
}

- (void)showAlert:(NSString *)alert withDescription:(NSString *)msg {
    if(!msg){
        msg = @"";
    }
    [[NSAlert alertWithMessageText:alert defaultButton:@"OK"
                   alternateButton:nil otherButton:nil informativeTextWithFormat:msg]
     
     beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow]
     modalDelegate:self
     didEndSelector:NULL
     contextInfo:NULL];
}


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
        
    }
    [self.progressIndicator startAnimation:self];
    [self.progressCancelButton setEnabled:YES];
    [NSApp beginSheet:self.progressPanel
       modalForWindow:[[NSApplication sharedApplication] mainWindow]
        modalDelegate:self
       didEndSelector:NULL
          contextInfo:NULL];
}

- (void)stopProgressPanel {
    [self.progressPanel orderOut:self];
    [NSApp endSheet:self.progressPanel returnCode:0];
}

- (void)setProgress:(double)progress {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.progressIndicator incrementBy:progress];
    }];
}

-(void)awakeFromNib{
    [[ODUStatus sharedStatus]addObserver:self forKeyPath:@"serverStatus" options:NSKeyValueObservingOptionNew context:NULL];
    
    [[ODUStatus sharedStatus]addObserver:self forKeyPath:@"userList" options:NSKeyValueObservingOptionNew context:NULL];
    
    [[ODUStatus sharedStatus]addObserver:self forKeyPath:@"groupList" options:NSKeyValueObservingOptionNew context:NULL];
    
    [[ODUStatus sharedStatus]addObserver:self forKeyPath:@"presetList" options:NSKeyValueObservingOptionNew context:NULL];

}
@end
