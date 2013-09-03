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
#import "AppProgress.h"

static const NSTimeInterval kHelperCheckInterval = 5.0; // how often to check whether to quit

@implementation AppDelegate


-(void)bgRunner:(void*)method withTimer:(int)timer{
    [NSTimer scheduledTimerWithTimeInterval:timer
                                     target:self
                                   selector:@selector(method)
                                   userInfo:nil
                                    repeats:YES];
}

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
    [self getDSUserPresets];
}


-(void)getDSStatus{
    self.dsStatus = @"Checking for Directory Server...";

    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] checkServerStatus:_serverName.stringValue withReply:^(BOOL connected) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(connected){
              self.dsStatus = [NSString stringWithFormat:@"Connected to %@",self.serverName.stringValue];
            }else{
                self.dsStatus = @"Not Connected to server";
            }
        }];
        [connection invalidate];
    }];

}


-(void)getDSUserPresets{
    [_refreshPreset setHidden:YES];
    [_presetStatus startAnimation:self];

    [_userPreset removeAllItems];
    [_userPreset addItemWithTitle:@"Getting Presets..."];

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
            [_refreshPreset setHidden:NO];
            [_presetStatus stopAnimation:self];
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
    [_serverUserList removeAllItems];
    [_serverUserList addItemWithTitle:@"Getting List of Users..."];
    
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
            [_serverUserList removeAllItems];
            if(!error){
                NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: NO];
                [_serverUserList addItemsWithTitles:[uArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: sortOrder]]];
                [dsUserArrayController setContent:uArray];
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
    [[connection remoteObjectProxy] checkCredentials:server withReply:^(BOOL authenticated) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(authenticated){
                self.dsStatus = @"The the username and password are correct";
                [self getDSUserPresets];
                [self getDSGroupList];
                [self getDSUserList];
            }else{
               self.dsStatus = @"The the username and password are not correct";
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

-(void)getUserPreferences{
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

//-------------------------------------------------------------------
//  App Delegate
//-------------------------------------------------------------------

- (void)applicationDidFinishLaunching:(NSNotification* )aNotification
{
    // Insert code here to initialize your application
    [self getUserPreferences];
    [self checkCredentials];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication* )theApplication{
    return YES;
}

-(void)applicationWillTerminate:(NSNotification *)notification{
    [self setUserPreferences];
}

@end

