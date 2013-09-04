//
//  AppController.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "AppController.h"
#import "FileService.h"
#import "OpenDirectoryService.h"
#import "ODUserBridge.h"

@implementation AppController

//-----------------------------------------------------------
//  Single User Creation 
//-----------------------------------------------------------

- (IBAction)makeSingleUserPressed:(id)sender{
    NSArray* requiredFields = [NSArray arrayWithObjects:_firstName,_lastName,_userName,_userCWID,_emailDomain,_defaultGroup, nil];
    
    for (NSTextField* i in requiredFields){
        if([i.stringValue isEqual: @""]){
            [self showAlert:@"Missing fileds" withDescription:@"Please fill out all fields"];
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
    
    NSMutableArray* ug = [NSMutableArray new];
    if(_commStudent){
        [ug addObject:@"smc"];
    }
    
    //do get other groups...
    
    for (NSString* i in _groupEntries.itemTitles){
        [ug addObject:i];
    }
    //then...
    NSArray* userGroups = [NSArray arrayWithArray:ug];
    
    if(![_uuid.stringValue isEqualToString:@""]){
        user.userUUID = _uuid.stringValue;
    }
    
    if([_commStudent state]){
        user.keyWord = @"CommStudent";
    }
    else{
        user.keyWord = @"NonComm";
    }
    
    /* Set up the Serve Object */
    Server* server = nil;
    server = [Server new];
    server.serverName = _serverName.stringValue;
    server.diradminName = _diradminName.stringValue;
    server.diradminPass = _diradminPass.stringValue;
    
    [self addSingleUser:user toServer:server andGroups:userGroups];
    
}

/* opendirectory-service xpc */
-(void)addSingleUser:(User*)user toServer:(Server*)server andGroups:(NSArray*)userGroups{
    NSString* progress = [NSString stringWithFormat:@"adding %@ to %@...", user.userName, server.serverName];
    [self startProgressPanelWithMessage:progress indeterminate:YES];

    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] addSingleUser:user toServer:server andGroups:userGroups withReply:^(NSError *error){
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


-(IBAction)overrideUUID:(id)sender{
    if([_overrideUID state]){
        [_uuid setHidden:FALSE];
    }else{
        [_uuid setHidden:TRUE];
        [_uuid setStringValue:@""];
    }
}

//-----------------------------------------------------------
//  Multiple User Creation
//-----------------------------------------------------------
- (IBAction)makeMultiUserPressed:(id)sender{
    NSError* error = nil;
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
    
    /* Set up the Serve Object */
    Server* server = [Server new];
    server.serverName = _serverName.stringValue;
    server.diradminName = _diradminName.stringValue;
    server.diradminPass = _diradminPass.stringValue;
    
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
    
    [self getUserArrayFromFile:user forServer:server];
}

/* file-service xpc */
-(void)getUserArrayFromFile:(User*)user forServer:(Server*)server{
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
                [self addListOfUsers:userlist usingPresetsIn:user toServer:server andGroups:dsgroups];
            }
        }];
        [connection invalidate];
    }];
}

/* opendirectory-service xpc */
-(void)addListOfUsers:(NSArray*)list usingPresetsIn:(User*)user toServer:(Server*)server andGroups:(NSArray*)userGroups{
    NSString* progress = [NSString stringWithFormat:@"adding %lu users to %@...", (unsigned long)[list count], server.serverName];
    [self startProgressPanelWithMessage:progress indeterminate:NO];
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] addListOfUsers:list usingPresetsIn:user toServer:server andGroups:userGroups withReply:^(NSError *error) {
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


//-----------------------------------------------------------
//  DSImport File Creation
//-----------------------------------------------------------
- (IBAction)makeDSImportFilePressed:(id)sender{
    NSError* error = nil;
    
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
    
    if(error){
        [self showAlert:@"Couldn't use the selected file" withDescription:@"Make sure it's in you home directory"];
        return;
    }
    
    NSURL* exportFileURL =[self getURLFromSavePanel];
    
    if(!exportFileURL){
        [self showAlert:@"You must specify a location to save the file" withDescription:nil];
        return;
    }

    [[NSData data] writeToURL:exportFileURL options:0 error:&error];
    if(!error){
        [self startProgressPanelWithMessage:@"Creating DSImport File..." indeterminate:YES];
        user.exportFile = [NSFileHandle fileHandleForWritingToURL:exportFileURL error:&error];
        [self makeDSImportFile:user];
    }else{
        [self showAlert:@"We couldn't write to that file" withDescription:nil];
    }

}



/* file-service xpc */
-(void)makeDSImportFile:(User*)user{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kFileServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(FileService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] makeMultiUserFile:user
                                            withReply:^(NSError* error){
                                                
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self stopProgressPanel];
            if(error){
                [self showErrorAlert:error];
            }
        }];
        [connection invalidate];
    }];
}





//

//-------------------------------------------
//  Password Reset
//-------------------------------------------
- (IBAction)resetPasswordPressed:(id)sender{
    
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
    [self resetUserPassword:user onServer:server];
    
}

-(void)resetUserPassword:(User*)user onServer:(Server*)server{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] resetUserPassword:user onServer:server withReply:^(NSError *error) {
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


//-------------------------------------------
//  IBActions
//-------------------------------------------


- (IBAction)chooseImportFile:(id)sender{
    NSURL* importFile = [self getURLFromOpenPanel];
    if(importFile){
        _importFilePath.stringValue = importFile.path;
    }
}

-(IBAction)addGroupForUser:(id)sender{
    [_groupEntries insertItemWithTitle:[_serverGroupListSingleUser titleOfSelectedItem] atIndex:0];
    [_groupEntries selectItemAtIndex:0];
}

-(IBAction)removeGroupForUser:(id)sender{
    if( _groupEntries.indexOfSelectedItem > -1){
        [_groupEntries removeItemAtIndex:[_groupEntries indexOfSelectedItem]];
    }
}

-(IBAction)addGroupMatchEntry:(id)sender{
    NSString* match = [_fileClassList stringValue];
    NSString* group = [_serverGroupList titleOfSelectedItem];
    
    if(!groups)
        groups = [[NSMutableArray alloc] init];
    
    if([group isEqualToString:@""]||[match isEqualToString:@""])
        return;

    NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@:%@",group,match],@"description",group, @"group", match, @"match", nil];

    [groups addObject:dict];
    [groups sortUsingDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"group" ascending:YES], nil]];
    
    [arrayController setContent:groups];
}


-(IBAction)removeGroupMatchEntry:(id)sender{
    if(_groupMatchEntries.indexOfSelectedItem > -1){
        [groups removeObjectAtIndex:[_groupMatchEntries indexOfSelectedItem]];
        [arrayController setContent:groups];
    }
}

//-------------------------------------------
//  Progress Panel and Alert
//-------------------------------------------

- (void)showErrorAlert:(NSError *)error {
    [[NSAlert alertWithError:error] beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow]
                                               modalDelegate:self
                                              didEndSelector:nil
                                                 contextInfo:nil];
}

- (void)showAlert:(NSString *)alert withDescription:(NSString *)msg {
    if(!msg){
        msg = @"";
    }
    [[NSAlert alertWithMessageText:alert defaultButton:@"OK"
                   alternateButton:nil otherButton:nil informativeTextWithFormat:msg]
     
     beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow]
                modalDelegate:self
                 didEndSelector:nil
                 contextInfo:nil];
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
       didEndSelector:nil
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

- (void)setProgress:(double)progress withMessage:(NSString*)message {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.progressIndicator incrementBy:progress];
        self.progressMessage = message;
    }];
}

- (void)setProgressMsg:(NSString*)message{
    self.progressMessage = message;
}

- (IBAction)cancel:(id)sender {
    [self.progressPanel orderOut:self];
    [NSApp endSheet:self.progressPanel returnCode:1];
}

//-----------------------------
//  Open and Save panels
//-----------------------------

-(NSURL*)getURLFromSavePanel{
    NSURL* url;
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"txt"]];
    [savePanel setNameFieldStringValue:@"dsimport.txt"];
    
    if([savePanel runModal] == NSOKButton){
        url = [savePanel URL];
    }
    
    return url;
}

-(NSURL*)getURLFromOpenPanel{
    NSURL* url;
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setCanChooseDirectories:NO];
    
    if ( [openDlg runModal] == NSOKButton )
    {
       url = [openDlg URL];
    }
    return url;
}
@end
