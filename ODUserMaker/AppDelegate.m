//
//  AppDelegate.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "AppDelegate.h"
#import "SSKeychain.h"

static const NSTimeInterval kHelperCheckInterval = 5.0; // how often to check whether to quit

@implementation AppDelegate

-(void)bgRunner:(void*)method{
    [NSTimer scheduledTimerWithTimeInterval:2.0
                                     target:self
                                   selector:@selector(method)
                                   userInfo:nil
                                    repeats:YES];
}

//-------------------------------
//  Directory Severt 
//-------------------------------

- (IBAction)editServerName:(id)sender{
    [self getDirectoryServerStatus];
}

-(void)getDirectoryServerStatus{
    
    //To Do : This should really be done with DirectoryService API
    
    NSString* sn = self.serverName.stringValue;
    
    if([sn isEqual:@""]){
        self.dsStatus = @"No Server Specified.";
        [_dsServerStatus setState:0];

    }else{
        
        NSPipe *pipe1 = [[NSPipe alloc] init];
        NSPipe *resultPipe = [[NSPipe alloc] init];

        NSTask *odutil = [[NSTask alloc]init];
        [odutil setLaunchPath: @"/usr/bin/odutil"];
        [odutil setArguments:[NSArray arrayWithObjects:@"show",@"nodenames",nil]];
        [odutil setStandardOutput:pipe1];
        [odutil launch];
        
        NSTask* grepNode = [[NSTask alloc]init];
        [grepNode setLaunchPath:@"/usr/bin/egrep"];
        
        [grepNode setArguments:[NSArray arrayWithObjects:@"-w",sn,nil]];
        [grepNode setStandardInput:pipe1];
        [grepNode setStandardOutput:resultPipe];
        [grepNode launch];
        [grepNode waitUntilExit];
        
        NSData* result = [[resultPipe fileHandleForReading] readDataToEndOfFile];
        NSString* rc= [[NSString alloc] initWithData:result encoding:NSASCIIStringEncoding];
        //NSLog(@"here's the rc: %@",rc);
        
        
        NSRange textRange;
        textRange =[rc rangeOfString:@"Online"];
        if(textRange.location != NSNotFound){
            self.dsStatus = [NSString stringWithFormat:@"Connected to  Directory Server %@",sn];
            [_dsServerStatus setState:1];
        }else{
            self.dsStatus = [NSString stringWithFormat:@"Not Connected to  Directory Server %@",sn];
            [_dsServerStatus setState:0];
        }
        [self getUserPresets];

    }
}


-(void)getUserPresets{
    if(_dsServerStatus){
        NSLog(@"Getting Presets");
        NSString * svrldap = [NSString stringWithFormat:@"/LDAPv3/%@",_serverName.stringValue];
        NSTask *dscl = [[NSTask alloc]init];
        NSPipe *resultPipe = [[NSPipe alloc] init];

        [dscl setLaunchPath: @"/usr/bin/dscl"];
        [dscl setArguments:[NSArray arrayWithObjects:svrldap,@"-list",@"/PresetUsers",nil]];
        [dscl setStandardOutput:resultPipe];
        [dscl launch];
        [dscl waitUntilExit];
        
        NSData* result = [[resultPipe fileHandleForReading] readDataToEndOfFile];
        NSString* presetString= [[NSString alloc] initWithData:result encoding:NSASCIIStringEncoding];
        
        [_userPreset removeAllItems];

        if (![dscl isRunning]) {
            int status = [dscl terminationStatus];
            if (status == 0){
                NSArray *ary = [presetString componentsSeparatedByString:@"\n"];
                NSMutableArray *mAry = [(NSArray*)ary mutableCopy];
                [mAry removeObject:@""];
                [_userPreset addItemsWithTitles: mAry];
            }
        }
    }
}

//-----------------------
//  User Default 
//-----------------------
-(void)setUserDefaults{
    NSUserDefaults * setDefaults = [NSUserDefaults standardUserDefaults];
    @try {
        [setDefaults setObject:self.serverName.stringValue forKey:@"serverName"];
        [setDefaults setObject:self.diradminName.stringValue forKey:@"diradminName"];
        [SSKeychain setPassword:self.diradminPass.stringValue forService:[[NSBundle mainBundle] bundleIdentifier] account:self.diradminName.stringValue];
    }
    @catch (NSException *exception) {
    }
    
    
    
    
    //[setDefaults setObject:self.fileName.stringValue forKey:@"fileName"];
    
    [setDefaults synchronize];
}

-(void)getUserDefualts{
    NSUserDefaults *getDefaults = [NSUserDefaults standardUserDefaults];
    @try{
    self.serverName.stringValue = [getDefaults stringForKey:@"serverName"];
    self.diradminName.stringValue = [getDefaults stringForKey:@"diradminName"];
    
    //self.fileName.stringValue = [getDefaults stringForKey:@"fileName"];
    }
    @catch (NSException *exception) {
        [self setUserDefaults];
    }
    @finally {
        if(_diradminName.stringValue)
            self.diradminPass.stringValue = [SSKeychain passwordForService:[[NSBundle mainBundle] bundleIdentifier] account:self.diradminName.stringValue];
    }
}



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self getUserDefualts];
    self.dsStatus = @"Checking for Directory Server...";
    //[self dsRun];  // this just triggers the ds action task to run on another thread
    [self getDirectoryServerStatus];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication{
    [self setUserDefaults];
    return YES;
}

@end

