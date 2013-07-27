//
//  AppDelegate.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "AppDelegate.h"
#import "SSKeychain.h"
#import "NetworkService.h"
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

- (IBAction)editServerName:(id)sender{
    [self getDSStatus];
    [self getDSUserPresets];
    [self getDSGroupList];
}

- (IBAction)refreshUserPreferences:(id)sender{
    [self getDSUserPresets];
}


-(void)getDSStatus{
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
    //[self.refreshPreset setHidden:YES];
    //[self.presetStatus startAnimation:self];
    
    [_serverGroupList removeAllItems];
    [_serverGroupList addItemWithTitle:@"Getting List of Groups..."];
    
    Server* server = [Server new];
    server.serverName = _serverName.stringValue;
    server.diradminPass = _diradminPass.stringValue;
    server.diradminName = _diradminName.stringValue;
    
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] getGroupListFromServer:server withReply:^(NSArray *pArray, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_serverGroupList removeAllItems];
            if(!error){
                NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: NO];
                [_serverGroupList addItemsWithTitles:[pArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: sortOrder]]];
            }
            
            //[self.refreshPreset setHidden:NO];
            //[self.presetStatus stopAnimation:self];
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
        
        
        [SSKeychain setPassword:_diradminPass.stringValue forService:[[NSBundle mainBundle] bundleIdentifier] account:_diradminName.stringValue];
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

   
    if([getDefaults stringForKey:@"diradminName"])
        _diradminPass.stringValue = [SSKeychain passwordForService:[[NSBundle mainBundle] bundleIdentifier] account:[getDefaults stringForKey:@"diradminName"]];
    if([_defaultGroup.stringValue isEqualToString:@""])
        self.defaultGroup.stringValue = @"20";        
}


//-------------------------------------------------------------------
//  App Delegate
//-------------------------------------------------------------------

- (void)applicationDidFinishLaunching:(NSNotification* )aNotification
{
    // Insert code here to initialize your application
    [self getUserPreferences];
    self.dsStatus = @"Checking for Directory Server...";
    [self getDSStatus];
    [self getDSUserPresets];
    [self getDSGroupList];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication* )theApplication{
    return YES;
}

-(void)applicationWillTerminate:(NSNotification *)notification{
    [self setUserPreferences];
}

@end

