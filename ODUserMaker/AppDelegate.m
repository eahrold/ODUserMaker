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
    [self getDirectoryServerStatus];
}

- (IBAction)refreshUserPreferences:(id)sender{
    [self getDSUserPresets];
}


-(void)getDirectoryServerStatus{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = self;
    [connection resume];
    [[connection remoteObjectProxy] checkServerStatus:self.serverName.stringValue withReply:^(BOOL connected) {
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
    [self.refreshPreset setHidden:YES];
    [self.presetStatus startAnimation:self];

    [self.userPreset removeAllItems];
    [self.userPreset addItemWithTitle:@"Getting Presets..."];

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
            [self.userPreset removeAllItems];
            if(!error){
                NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: NO];
                [self.userPreset addItemsWithTitles:[pArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: sortOrder]]];
            }
            [self.refreshPreset setHidden:NO];
            [self.presetStatus stopAnimation:self];
        }];
        [connection invalidate];
    }];

   
}

-(void)getDSGroupList{
    //[self.refreshPreset setHidden:YES];
    //[self.presetStatus startAnimation:self];
    
    [self.serverGroupList removeAllItems];
    [self.serverGroupList addItemWithTitle:@"Getting List of Groups..."];
    
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
            [self.serverGroupList removeAllItems];
            if(!error){
                NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: NO];
                [self.serverGroupList addItemsWithTitles:[pArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: sortOrder]]];
            }
            
            //[self.refreshPreset setHidden:NO];
            //[self.presetStatus stopAnimation:self];
        }];
        [connection invalidate];
    }];
    
    
}

//-----------------------
//  User Default 
//-----------------------
-(void)setUserDefaults{
    NSUserDefaults* setDefaults = [NSUserDefaults standardUserDefaults];
    @try {
        [setDefaults setObject:self.defaultGroup.stringValue forKey:@"defaultGroup"];
        [setDefaults setObject:self.emailDomain.stringValue forKey:@"emailDomain"];
        [setDefaults setObject:self.serverName.stringValue forKey:@"serverName"];
        [setDefaults setObject:self.diradminName.stringValue forKey:@"diradminName"];
        [setDefaults setObject:self.importFilePath.stringValue forKey:@"lastFile"];
        
        NSMutableArray *presetList = [[NSMutableArray alloc] init];
        for(NSMenuItem* item in [self.userPreset itemArray]){
            [presetList addObject:item.title];
        }
        
        [setDefaults setObject:presetList forKey:@"userPreset"];
        
        
        [SSKeychain setPassword:self.diradminPass.stringValue forService:[[NSBundle mainBundle] bundleIdentifier] account:self.diradminName.stringValue];
    }
    @catch (NSException* exception) {
    }
    [setDefaults synchronize];
}

-(void)tryToSetInterface:(NSTextField*)filed withSetting:(NSString*)string{
    @try {
        filed.stringValue = string;}
    @catch (NSException* exception){}
}

-(void)getUserDefualts{
    NSUserDefaults* getDefaults = [NSUserDefaults standardUserDefaults];
    
    [self tryToSetInterface:_serverName withSetting:[getDefaults stringForKey:@"serverName"]];
    [self tryToSetInterface:_defaultGroup withSetting:[getDefaults stringForKey:@"defaultGroup"]];
    [self tryToSetInterface:_diradminName withSetting:[getDefaults stringForKey:@"diradminName"]];
    [self tryToSetInterface:_emailDomain withSetting:[getDefaults stringForKey:@"emailDomain"]];
    [self tryToSetInterface:_importFilePath withSetting:[getDefaults stringForKey:@"lastFile"]];


   
    if([getDefaults stringForKey:@"diradminName"])
        self.diradminPass.stringValue = [SSKeychain passwordForService:[[NSBundle mainBundle] bundleIdentifier] account:[getDefaults stringForKey:@"diradminName"]];
    if([_defaultGroup.stringValue isEqualToString:@""])
        self.defaultGroup.stringValue = @"20";        
}



- (void)applicationDidFinishLaunching:(NSNotification* )aNotification
{
    // Insert code here to initialize your application
    [self getUserDefualts];
    self.dsStatus = @"Checking for Directory Server...";
    [self getDirectoryServerStatus];
    [self getDSUserPresets];
    [self getDSGroupList];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication* )theApplication{
    [self setUserDefaults];
    return YES;
}

@end

