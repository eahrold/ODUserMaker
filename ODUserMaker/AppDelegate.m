//
//  AppDelegate.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "AppDelegate.h"
#import "SSKeychain.h"
#import "OpenDirectoryService.h"
#import "ODUserBridge.h"

static const NSTimeInterval kHelperCheckInterval = 5.0; // how often to check whether to quit

@implementation AppDelegate


//-------------------------------
//  Directory Sever 
//-------------------------------


- (IBAction)editPassword:(id)sender{
    [self checkCredentials];
}

- (IBAction)editServerName:(id)sender{
    if([_diradminPass.stringValue isEqualToString:@""]){
        [self getKeychainPass];
    }
    [self checkCredentials];
}

- (IBAction)refreshUserPreferences:(id)sender{
    [self checkCredentials];
}


-(void)getDSStatus{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] checkServerStatus:_serverName.stringValue withReply:^(OSStatus connected) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSColor* tc;
            if(connected == 0){
                tc = [NSColor colorWithCalibratedRed:0.0 green:0.7 blue:0.0 alpha:1.0];
            }else if (connected == 1){
                tc = [NSColor colorWithCalibratedRed:0.7 green:0.6 blue:0.0 alpha:1.0];
            }else{
                tc = [NSColor redColor];
            }
         [_dsStatusTF setTextColor:tc];
        }];
        [connection invalidate];
    }];

}


-(void)getDSUserPresets{
    Server* server = [Server new];
    server.serverName = _serverName.stringValue;
    server.diradminPass = _diradminPass.stringValue;
    server.diradminName = _diradminName.stringValue;
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] getUserPresets:server withReply:^(NSArray *pArray, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_userPreset removeAllItems];
            if(!error){
                NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: NO];
                [_userPreset addItemsWithTitles:[pArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: sortOrder]]];
            }
        }];
        [connection invalidate];
    }];

   
}

-(void)getSettingsForPreset:(NSString*)preset{
    Server* server = [Server new];
    server.serverName = _serverName.stringValue;
    server.diradminPass = _diradminPass.stringValue;
    server.diradminName = _diradminName.stringValue;
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] getSettingsForPreset:preset withServer:server withReply:^(NSDictionary *settings, NSError *error) {
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


-(void)getDSGroupList{

    [dsGroupArrayController setContent:[NSArray arrayWithObject:@"Getting List of Groups..."]];

    Server* server = [Server new];
    server.serverName = _serverName.stringValue;
    server.diradminPass = _diradminPass.stringValue;
    server.diradminName = _diradminName.stringValue;
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] getGroupListFromServer:server withReply:^(NSArray *gArray, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_serverGroupList removeAllItems];
            if(!error){
                [dsGroupArrayController setContent:gArray];
            }
        }];
        [connection invalidate];
    }];
    
    
}

-(void)getDSUserList{
    [_userListStatus setHidden:NO];
    [_userListStatus startAnimation:self];
    
    [_statusUpdate setStringValue:@"Getting user List..."];
        
    Server* server = [Server new];
    server.serverName = _serverName.stringValue;
    server.diradminPass = _diradminPass.stringValue;
    server.diradminName = _diradminName.stringValue;
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] getUserListFromServer:server withReply:^(NSArray *uArray, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_statusUpdate setStringValue:@""];
            [_userListStatus setHidden:YES];
            [_userListStatus stopAnimation:self];
            if(!error){
                NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
                NSArray* a = [uArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
                [_userList addItemsWithObjectValues:a];
                [_userList setStringValue:[a objectAtIndex:0]];

            }
        }];
        [connection invalidate];
    }];
    
    
}

-(void)checkCredentials{
    /* don't bother checking untill everything is in place */
    if([_diradminName.stringValue isEqualToString:@""] ||
       [_diradminPass.stringValue isEqualToString:@""] ||
       [_diradminPass.stringValue isEqualToString:@""]){
        self.dsStatus = @"";
        return;
    }
    
    [_refreshPreset setHidden:YES];
    [_presetStatus startAnimation:self];
    
    [_userPreset removeAllItems];
    [_userPreset addItemWithTitle:@"Getting Presets..."];

    
    self.dsStatus = @"Checking user credentials";

    Server* server = [Server new];
    server.serverName = _serverName.stringValue;
    server.diradminPass = _diradminPass.stringValue;
    server.diradminName = _diradminName.stringValue;
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] checkCredentials:server withReply:^(OSStatus status) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_refreshPreset setHidden:NO];
            [_presetStatus stopAnimation:self];
            // here are the status returns
            // -1 No Node
            // -2 locally connected, but wrong password
            // -3 proxy but wrong auth password
            // 0 Authenticated locally
            // 1 Authenticated over proxy
            if(status < 0 ){
                [_dsServerStatus setImage:[NSImage imageNamed:@"connected-offline.tiff"]];
                
            }
            if(status == -1){
            }else if (status == -2){
                [_dsServerStatus setState:NO];
                self.dsStatus = @"Locally connected, but username or password are incorrect";
            }else if (status == -3){
                [_dsServerStatus setState:NO];
                self.dsStatus = @"We could not connect to the server.";
            }else if (status == 0){
                [_dsServerStatus setState:YES];
                self.dsStatus = @"The the username and password are correct, connected locally.";
                [_dsServerStatus setImage:[NSImage imageNamed:@"connected-local.tiff"]];
                [self getDSUserPresets];
                [self getDSGroupList];
                [self getDSUserList];
            }else if (status == 1){
                [_dsServerStatus setState:YES];
                self.dsStatus = @"The the username and password are correct, connected over proxy";
                [_dsServerStatus setImage:[NSImage imageNamed:@"connected-proxy.tiff"]];
                [self getDSUserPresets];
                [self getDSGroupList];
                [self getDSUserList];
            }
        }];
        [connection invalidate];
    }];
}



//--------------------------------------------------------------------------
//  User Preferences/Defaults 
//--------------------------------------------------------------------------
-(void)setUserPreferences{
    NSUserDefaults* setDefaults = [NSUserDefaults standardUserDefaults];
    @try {
        [setDefaults setObject:_defaultGroup.stringValue forKey:@"defaultGroup"];
        [setDefaults setObject:_emailDomain.stringValue forKey:@"emailDomain"];
        [setDefaults setObject:_serverName.stringValue forKey:@"serverName"];
        [setDefaults setObject:_diradminName.stringValue forKey:@"diradminName"];
        [setDefaults setObject:_importFilePath.stringValue forKey:@"lastFile"];

        
        NSMutableArray *presetList = [[NSMutableArray alloc] init];
        for(NSMenuItem* item in [_userPreset itemArray]){
            [presetList addObject:item.title];
        }
        
        [setDefaults setObject:presetList forKey:@"userPreset"];
        
        NSString* kcacct =[NSString stringWithFormat:@"%@:%@",_diradminName.stringValue,_serverName.stringValue];
        [SSKeychain setPassword:_diradminPass.stringValue forService:[[NSBundle mainBundle] bundleIdentifier] account:kcacct];
    }
    @catch (NSException* exception) {
    }
    [setDefaults synchronize];
}

-(void)tryToSetIBOutlet:(NSTextField*)field withSetting:(NSString*)string{
    @try {
        field.stringValue = string;
    }@catch (NSException* exception){
        /* just ignore errors*/
    }
    
}

-(BOOL)getUserPreferences{
    NSUserDefaults* getDefaults = [NSUserDefaults standardUserDefaults];
    [self tryToSetIBOutlet:_serverName withSetting:[getDefaults stringForKey:@"serverName"]];
    [self tryToSetIBOutlet:_defaultGroup withSetting:[getDefaults stringForKey:@"defaultGroup"]];
    [self tryToSetIBOutlet:_diradminName withSetting:[getDefaults stringForKey:@"diradminName"]];
    [self tryToSetIBOutlet:_emailDomain withSetting:[getDefaults stringForKey:@"emailDomain"]];

    
    if([getDefaults stringForKey:@"diradminName"]){
        [self getKeychainPass];
    }
    if([_defaultGroup.stringValue isEqualToString:@""])
        self.defaultGroup.stringValue = @"20";
    return YES;
}

-(void)getKeychainPass{
    NSString* dan = _diradminName.stringValue;
    NSString* sn = _serverName.stringValue;
    
    if(![dan isEqualToString:@""] || ![sn isEqualToString:@""]){
    
        NSString* kcAccount = [NSString stringWithFormat:@"%@:%@",dan,sn];
        NSString* kcPass = [SSKeychain passwordForService:
                            [[NSBundle mainBundle] bundleIdentifier] account:kcAccount];
        if(kcPass){
            _diradminPass.stringValue = kcPass;
        }else{
            _diradminPass.stringValue = @"";
        }
    }
}

-(IBAction)showSettingsWindow:(id)sender{
    [NSApp beginSheet:_settings
       modalForWindow:_window
        modalDelegate:self
       didEndSelector:nil
          contextInfo:NULL];
}

//-----------------------------
//  Settings Panel
//-----------------------------
- (IBAction)settingsDone:(id)sender{
    [self.settings orderOut:self];
    [NSApp endSheet:self.settings returnCode:0];
}


//-------------------------------------------------------------------
//  App Delegate
//-------------------------------------------------------------------

- (void)applicationDidFinishLaunching:(NSNotification* )aNotification
{
    [self showSettingsWindow:nil];
    // Insert code here to initialize your application
    [_dsServerStatus setState:NO];
    if([self getUserPreferences]){
        [self checkCredentials];
    }
    
    [self getSettingsForPreset:@"test"];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication* )theApplication{
    return YES;
}

-(void)applicationWillTerminate:(NSNotification *)notification{
    [self setUserPreferences];
}

@end

