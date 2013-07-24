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

//-------------------------------------------
//  Progress Panel and Alert
//-------------------------------------------

- (void)showErrorAlert:(NSError *)error {
    [[NSAlert alertWithError:error] beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow]
                                               modalDelegate:self
                                              didEndSelector:nil
                                                 contextInfo:nil];
}

- (void)startProgressPanelWithMessage:(NSString*)message indeterminate:(BOOL)indeterminate {
    /* Display a progress panel as a sheet */
    self.progressMessage = message;
    if (indeterminate) {
        [self.progressIndicator setIndeterminate:YES];
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

//-----------------------------------------------------------
//  NSXPC Connections
//-----------------------------------------------------------

/* file-service xpc */
-(void)addListOfUsers:(User*)user toServer:(Server*)server{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kFileServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Exporter)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] makeExportFile:user withReply:^(NSError* error,NSDictionary* groups){
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self stopProgressPanel];
            if(error){
                [self showErrorAlert:error];
            }else{
                //[self uploadUserList:user toServer:server];
            }
        }];
        [connection invalidate];
    }];
}


-(void)addUser:(User*)user toServer:(Server*)server{
    self.isSingleUser = YES;
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kFileServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Exporter)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] makeSingelUserFile:user withReply:^(NSError*error,NSString* reply){
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self stopProgressPanel];
            if(error){
                [self showErrorAlert:error];
            }else{
                [self uploadUserList:user toServer:server];
            }


        }];
        [connection invalidate];
    }];
}

/* network-service xpc */
-(void)uploadUserList:(User*)user toServer:(Server*)server{
    [self startProgressPanelWithMessage:@"Uploading User..." indeterminate:NO];
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kUploaderServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Uploader)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] uploadToServer:server user:user withReply:^(NSString* response){
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSLog(@"%@",response);
            if(self.isSingleUser){
                [self addUser:user toGroup:[[NSMutableArray alloc]init] toServer:server];
            }else{
                
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

//-------------------------------------------
//  IBActions
//-------------------------------------------

- (IBAction)makeSingleUserPressed:(id)sender{
    NSError* error = nil;
    [self startProgressPanelWithMessage:@"Adding User..." indeterminate:NO];
    
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
    
    /* Create the file and  set up the FileHandles */
    NSURL* exportFile = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(),user.userName]];
    if (![[NSData data] writeToURL:exportFile options:0 error:&error]) {
        [self stopProgressPanel];
        [self showErrorAlert:error];
        return;
    }
    
    user.exportFile = [NSFileHandle fileHandleForWritingToURL:exportFile error:&error];
    server.exportFile = [NSFileHandle fileHandleForReadingFromURL:exportFile error:&error];
    [self addUser:user toServer:server];
    
}

- (IBAction)makeImportFilePressed:(id)sender{
    NSError* error = nil;

    [self startProgressPanelWithMessage:@"Making User List..." indeterminate:YES];

    User* user = [User new];
    user.emailDomain = _emailDomain.stringValue;
    user.primaryGroup = _defaultGroup.stringValue;
    user.userPreset = [ _userPreset titleOfSelectedItem];
    user.keyWord = @"";
    user.groupList = [_groupMatchEntries itemArray];
    NSMenuItem* mymen = [user.groupList objectAtIndex:0];
    
    NSLog(@"%@",mymen.title);
    
    if(![_userFilter.stringValue isEqualToString:@""]){
        user.userFilter = _userFilter.stringValue;
    }else{
        user.userFilter = @" ";
    }
    
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
   
//    if(error){
//        [self stopProgressPanel];
//        [self showErrorAlert:error];
//        return;
//    }
    
    [self addListOfUsers:user toServer:server];
}

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

-(IBAction)addGroupMatchEntry:(id)sender{
    NSString* match = _fileClassList.stringValue;
    NSString* group = [_serverGroupList titleOfSelectedItem];
    [_groupMatchEntries addItemWithTitle:[NSString stringWithFormat:@"%@:%@",match,group]];
}

-(IBAction)removeGroupMatchEntry:(id)sender{
    [_groupMatchEntries removeItemAtIndex:[_groupMatchEntries indexOfSelectedItem]];
}

@end
