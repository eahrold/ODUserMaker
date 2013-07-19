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
    // Display a progress panel as a sheet
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

-(void)addListOfUsers:(User*)user withServer:(Server*)server{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kFileServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Exporter)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] makeExportFile:user withReply:^(NSError*error,NSString* msg){
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self stopProgressPanel];
            if(error){
                [self showErrorAlert:error];
            }else{
                //[self uploadFileLocally:user withServer:server];
            }
        }];
        [connection invalidate];
    }];
}


-(void)addUser:(User*)user withServer:(Server*)server{
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
                [self uploadFileLocally:user withServer:server];
            }


        }];
        [connection invalidate];
    }];
}

-(void)uploadFileLocally:(User*)user withServer:(Server*)server{
    [self startProgressPanelWithMessage:@"Uploading User..." indeterminate:NO];
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kUploaderServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Uploader)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] uploadToServer:server user:user withReply:^(NSString* response){
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSLog(@"%@",response);
            [self stopProgressPanel];
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
    
    // Set up the User Object
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
    
    // Set up the Serve Object
    Server* server = nil;
    server = [Server new];
    server.serverName = _serverName.stringValue;
    server.diradminName = _diradminName.stringValue;
    server.diradminPass = _diradminPass.stringValue;
    
    // Create the file and  set up the FileHandles
    NSURL* exportFile = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(),user.userName]];
    if (![[NSData data] writeToURL:exportFile options:0 error:&error]) {
        [self stopProgressPanel];
        [self showErrorAlert:error];
        return;
    }
    
    user.exportFile = [NSFileHandle fileHandleForWritingToURL:exportFile error:&error];
    server.exportFile = [NSFileHandle fileHandleForReadingFromURL:exportFile error:&error];
    [self addUser:user withServer:server];
    
}

- (IBAction)makeImportFilePressed:(id)sender{
    NSError* error = nil;

    [self startProgressPanelWithMessage:@"Making User List..." indeterminate:YES];

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
    
    Server* server = [Server new];
    server.serverName = _serverName.stringValue;
    server.diradminName = _diradminName.stringValue;
    server.diradminPass = _diradminPass.stringValue;
        
    // Set up the import and export FileHandles
    NSURL * importFileURL = [NSURL fileURLWithPath:_importFilePath.stringValue];
    user.importFileHandle = [NSFileHandle fileHandleForReadingFromURL:importFileURL error:&error];
    
    NSString* timeStamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
    NSURL* exportFile = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(),timeStamp]];
    
    // Touch the file so the file handle can get create successfully
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
    
    [self addListOfUsers:user withServer:server];
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
    


@end
