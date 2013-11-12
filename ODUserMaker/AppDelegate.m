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

@implementation AppDelegate


//-------------------------------
//  Directory Sever 
//-------------------------------

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
            if(!error){
                [dsUserPresetController setContent:pArray];
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
            [_userList removeAllItems];
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
    [[connection remoteObjectProxy] checkServerStatus:server withReply:^(OSStatus status)  {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_refreshPreset setHidden:NO];
            [_presetStatus stopAnimation:self];
            NSLog(@"ODUM Node Status: %d",status);
            // here are the status returns
            // -1 No Node
            // -2 locally connected, but wrong password
            // -3 proxy but wrong auth password
            // 0 Authenticated locally
            // 1 Authenticated over proxy
            if(status < 0){
                [_dsServerStatus setImage:[NSImage imageNamed:@"connected-offline.tiff"]];
            }
            
            if(status == -1){
                [_dsServerStatus setState:NO];
                self.dsStatus = @"Could Not Connect to Remote Node";
            }else if (status == -2){
                [_dsServerStatus setState:NO];
                self.dsStatus = @"Locally connected, but username or password are incorrect";
            }else if (status == -3){
                [_dsServerStatus setState:NO];
                self.dsStatus = @"Could Not Connect to proxy server.";
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
-(void)setDefaults:(NSUserDefaults**)defaults withString:(NSString*)string forKey:(NSString*)key{
    
    if(string && ![string isEqualToString:@""]){
        [*defaults setObject:string forKey:key];
    }else{
        [*defaults removeObjectForKey:key];
    }
}

-(void)setUserPreferences{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

    [self setDefaults:&defaults withString:_serverName.stringValue forKey:@"serverName"];
    [self setDefaults:&defaults withString:_diradminName.stringValue forKey:@"diradminName"];

    [self setDefaults:&defaults withString:_choosePresetButton.title forKey:@"lastSelectedPreset"];
    [self setDefaults:&defaults withString:_emailDomain.stringValue forKey:@"emailDomain"];
    [self setDefaults:&defaults withString:_defaultGroup.stringValue forKey:@"defaultGroup"];
    
    [self setDefaults:&defaults withString:_sharePoint.stringValue forKey:@"presetSharePoint"];
    [self setDefaults:&defaults withString:_sharePath.stringValue forKey:@"presetSharePath"];
    [self setDefaults:&defaults withString:_NFSPath.stringValue forKey:@"presetNFSPath"];
    [self setDefaults:&defaults withString:_userShell.stringValue forKey:@"presetUserShell"];
    
    [self setDefaults:&defaults withString:_extraGroupDescription.stringValue forKey:@"extraGroupDescription"];
    [self setDefaults:&defaults withString:_extraGroupShortName.stringValue forKey:@"extraGroupShortName"];
    
    NSString* kcacct =[NSString stringWithFormat:@"%@:%@",_diradminName.stringValue,_serverName.stringValue];
    [SSKeychain setPassword:_diradminPass.stringValue forService:[[NSBundle mainBundle] bundleIdentifier] account:kcacct];
   
    [defaults synchronize];
}

-(void)setTextField:(NSTextField*)field withString:(NSString*)string{
    if(string){
        field.stringValue = string;
    }
}

-(BOOL)getUserPreferences{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [self setTextField:_serverName withString:[defaults stringForKey:@"serverName"]];

    [self setTextField:_defaultGroup withString:[defaults stringForKey:@"defaultGroup"]];
    [self setTextField:_diradminName withString:[defaults stringForKey:@"diradminName"]];
    [self setTextField:_emailDomain withString:[defaults stringForKey:@"emailDomain"]];

    [self setTextField:_userShell withString:[defaults stringForKey:@"userShell"]];
    [self setTextField:_sharePoint withString:[defaults stringForKey:@"presetSharePoint"]];
    [self setTextField:_sharePath withString:[defaults stringForKey:@"presetSharePath"]];
    [self setTextField:_NFSPath withString:[defaults stringForKey:@"presetNFSPath"]];
    
    if ([defaults stringForKey:@"lastSelectedPreset"]){
        _choosePresetButton.title = [defaults stringForKey:@"lastSelectedPreset"];
    }
    
    [_extraGroupShortName removeAllItems];
    if([defaults stringForKey:@"extraGroupShortName"]){
        _extraGroupShortName.stringValue = [defaults stringForKey:@"extraGroupShortName"];
        NSLog(@"setting group name as %@",[defaults stringForKey:@"extraGroupShortName"]);
    }
    
    [self setTextField:_extraGroupDescription withString:[defaults stringForKey:@"extraGroupDescription"]];

    if([defaults stringForKey:@"diradminName"]){
        [self getKeychainPass:nil];
    }
    
    if([_defaultGroup.stringValue isEqualToString:@""])
        _defaultGroup.stringValue = @"20";
    return YES;
}

-(IBAction)getKeychainPass:(id)sender {
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
//  IBActions
//-----------------------------
#pragma mark --IBActions

- (IBAction)settingsDone:(id)sender{
    [self.settings orderOut:self];
    [NSApp endSheet:self.settings returnCode:0];
    
    if(![_extraGroupDescription.stringValue isEqualToString:@""]){
        _extraGroup.title = _extraGroupDescription.stringValue;
    }
}


- (IBAction)editPassword:(id)sender{
    [self checkCredentials];
}

- (IBAction)editServerName:(id)sender{
    if([_diradminPass.stringValue isEqualToString:@""]){
        [self getKeychainPass:nil];
    }
    [self checkCredentials];
}

- (IBAction)refreshUserPreferences:(id)sender{
    [self checkCredentials];
}

-(IBAction)customPreset:(id)sender{
    _usingPreset.stringValue = @"Custom";
    _choosePresetButton.title = @"Custom";

}
-(IBAction)chooseUserPreset:(id)sender{
    NSDictionary*dict = [[dsUserPresetController content] objectAtIndex:[_userPreset indexOfSelectedItem]];
    NSString* us = [dict objectForKey:@"userShell"];
    NSString* spo = [dict objectForKey:@"sharePoint"];
    NSString* spa = [dict objectForKey:@"sharePath"];
    NSString* nhp = [dict objectForKey:@"NFSHome"];
    _usingPreset.stringValue = [_userPreset titleOfSelectedItem];
    _choosePresetButton.title = [_userPreset titleOfSelectedItem];

    
    if(us){
        _userShell.stringValue = us;
    }else{
        _userShell.stringValue = @"";
    }
    
    if(spo){
        _sharePoint.stringValue = spo;
    }else{
        _sharePoint.stringValue = @"";
    }
    
    if(spa){
        _sharePath.stringValue = spa;
    }else{
        _sharePath.stringValue = @"";
    }
    
    if(nhp){
        _NFSPath.stringValue = nhp;
    }else{
        _NFSPath.stringValue = @"";
    }
    
}


//-------------------------------------------------------------------
//  App Delegate
//-------------------------------------------------------------------

- (void)applicationDidFinishLaunching:(NSNotification* )aNotification
{
    // Insert code here to initialize your application
    [_dsServerStatus setState:NO];

    if([self getUserPreferences]){
        [self checkCredentials];
        if(![_extraGroupDescription.stringValue isEqualToString:@""]){
            _extraGroup.title = _extraGroupDescription.stringValue;
        }else{
            [_extraGroup setHidden:YES];
        }
    }
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication* )theApplication{
    return YES;
}

-(void)applicationWillTerminate:(NSNotification *)notification{
    [self setUserPreferences];
}

@end

