//
//  AppController.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "AppController.h"
#import "NetworkService.h"
#import "FileService.h"
#import "OpenDirectoryService.h"
#import "AppProgress.h"
#import "SSKeychain.h"

@implementation AppController

//-----------------------------------------------------------
//  Single User Creation 
//-----------------------------------------------------------

- (IBAction)makeSingleUserPressed:(id)sender{
    _isSingleUser = YES;
    NSError* error = nil;
    
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
    
    /* Create the file and set up the FileHandles */
    NSURL* exportFile = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(),user.userName]];
    if (![[NSData data] writeToURL:exportFile options:0 error:&error]) {
        [self stopProgressPanel];
        [self showErrorAlert:error];
        return;
    }
    
    //user.exportFile = [NSFileHandle fileHandleForWritingToURL:exportFile error:&error];
    //server.exportFile = [NSFileHandle fileHandleForReadingFromURL:exportFile error:&error];
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

/* opendirectory-service xpc */
-(void)addUser:(User*)user toGroup:(NSMutableArray*)group toServer:(Server*)server{
    
    if(self.commStudent.state){
        [group addObject:@"smc"];
    }
    
    /* lock down the mutable array before passing off to the xpc service */
    NSArray *dsGroups = [NSArray arrayWithArray:group];
    
    if(dsGroups.count == 0)
    {
        [self stopProgressPanel];
        return;
    }
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] addUser:user toGroup:dsGroups toServer:server withReply:^(NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self stopProgressPanel];
            if(error){
                NSLog(@"Error: %@",[error localizedDescription]);
                [self showErrorAlert:error];
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
    
    /* we've got to touch the file befor creating the file handle */
    if (![[NSData data] writeToURL:exportFile options:0 error:&error]) {
        [self stopProgressPanel];
        [self showErrorAlert:error];
        return;
    }
    
    user.exportFile = [NSFileHandle fileHandleForWritingToURL:exportFile error:&error];
    server.exportFile = [NSFileHandle fileHandleForReadingFromURL:exportFile error:&error];
    
    [self getUserArrayFromFile:user forServer:server];
}

- (IBAction)makeDSImportFilePressed:(id)sender{
    NSError* error = nil;
    [self startProgressPanelWithMessage:@"Creating DSImport File..." indeterminate:YES];
    
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
    
    /* we've got to touch the file befor creating the file handle */
    if (![[NSData data] writeToURL:exportFile options:0 error:&error]) {
        [self stopProgressPanel];
        [self showErrorAlert:error];
        return;
    }
    
    user.exportFile = [NSFileHandle fileHandleForWritingToURL:exportFile error:&error];
    server.exportFile = [NSFileHandle fileHandleForReadingFromURL:exportFile error:&error];
    
    [self makeMultiUserFile:user toServer:server];
}



/* file-service xpc */
-(void)makeMultiUserFile:(User*)user toServer:(Server*)server{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kFileServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(FileService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] makeMultiUserFile:user
                                         andGroupList:groups
                                            withReply:^(NSArray* dsgroups,NSNumber* ucount, NSError* error){
                                                
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            if(error){
                [self stopProgressPanel];
                [self showErrorAlert:error];
            }else{
                dsGroupList = [[NSArray alloc ]initWithArray:dsgroups];
                user.userCount = ucount;
                [self uploadUserList:user toServer:server];
            }
            
        }];
        [connection invalidate];
    }];
}

/* file-service xpc */
-(void)getUserArrayFromFile:(User*)user forServer:(Server*)server{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kFileServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(FileService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] makeUserArray:user
                                         andGroupList:groups
                                            withReply:^(NSArray* dsgroups,NSArray* userlist, NSError* error){
                                                
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                if(error){
                    [self stopProgressPanel];
                    [self showErrorAlert:error];
                }else{
                    dsGroupList = [[NSArray alloc ]initWithArray:dsgroups];
                    user.userList = userlist;
                }
            }];
            [connection invalidate];
        }];
}

/* opendirectory-service xpc */
-(void)addGroupsToServer:(Server*)server{
    
    if([dsGroupList count] == 0)
    {
        [self stopProgressPanel];
        return;
    }
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] addGroups:dsGroupList
                                     toServer:server
                                    withReply:^(NSError *error){
                                        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self stopProgressPanel];
            if(error){
                NSLog(@"Error: %@",[error localizedDescription]);
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
//  Common Methods
//-------------------------------------------

/* network-service xpc */
-(void)uploadUserList:(User*)user toServer:(Server*)server{
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kUploaderServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Uploader)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    
    [connection resume];
    [[connection remoteObjectProxy] uploadToServer:server
                                              user:user
                                         withReply:^(NSString* response,NSError* error){
                                             
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(error){
                NSLog(@"Error: %@",[error localizedDescription]);
                [self stopProgressPanel];
                [self showErrorAlert:error];
            }else{
                if(self.isSingleUser){
                    [self addUser:user toGroup:[NSMutableArray new] toServer:server];
                }else{
                    [self addGroupsToServer:server];
                }
            }
        }];
        [connection invalidate];
    }];

}


//-------------------------------------------
//  IBActions
//-------------------------------------------


- (IBAction)chooseImportFile:(id)sender{
    
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setCanChooseDirectories:NO];
    
    if ( [openDlg runModal] == NSOKButton )
    {
        NSURL* url = [openDlg URL];
        _importFilePath.stringValue = url.path;
    }
}


/*group matching methods*/
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
    [groups removeObjectAtIndex:[_groupMatchEntries indexOfSelectedItem]];
    [arrayController setContent:groups];
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


@end
