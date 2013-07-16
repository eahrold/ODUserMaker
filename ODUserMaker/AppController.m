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
//  Progress Panel
//-------------------------------------------

- (void)startProgressPanelWithMessage:(NSString *)message indeterminate:(BOOL)indeterminate {
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

- (void)setProgress:(double)progress withMessage:(NSString *)message {
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


-(void)addUser:(User*)user withServer:(Server*)server{
    NSLog(@"export file");
    NSXPCConnection *connection = [[NSXPCConnection alloc] initWithServiceName:kFileServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Exporter)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] makeSingelUserFile:user withReply:^(NSString *reply){
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            server.exportFile = reply;
            [self uploadFileLocally:user withServer:server];

        }];
        [connection invalidate];
    }];
}

-(void)uploadFileLocally:(User*)user withServer:(Server*)server{
    //NSLog(@"This is sn inside: %@, with name %@",server.exportFile,server.serverName);

    NSXPCConnection *connection = [[NSXPCConnection alloc] initWithServiceName:kUploaderServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Uploader)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] uploadToServer:server user:user withReply:^(NSString *response){
        
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
    [self startProgressPanelWithMessage:@"Adding User..." indeterminate:NO];
    
    // Set up the User Object
    User* user = nil;
    user = [User new];
    user.firstName = _firstName.stringValue;
    user.lastName = _lastName.stringValue;
    user.userName = _userName.stringValue;
    user.userCWID = _userCWID.stringValue;
    user.emailDomain = @"loyno.edu";
    user.primaryGroup = @"20";
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


    [self addUser:user withServer:server];
    
//    if(self.exportFile){
//        NSLog(@"This is the export file: %@", self.exportFile);
//
//    }
    //[self uploadFileLocally:user withServer:server];

    
      

}

- (IBAction)makeImportFilePressed:(id)sender{
    
}



@end
