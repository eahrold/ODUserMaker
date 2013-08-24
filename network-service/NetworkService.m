//
//  Uploader.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "NetworkService.h"
#import "AppProgress.h"

@interface Uploader ()
-(NSString*)dsImport:(User*)user withServer:(Server*)server;
-(void)eyeCandy;
@end


@implementation Uploader

-(NSString*)dsImport:(User*)user withServer:(Server*)server{    
    
    //  We need to do this get around the sandbox for the NSTask
    NSString* dsimportFile = [NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(),user.userName];
    NSFileHandle* fh = [NSFileHandle fileHandleForWritingAtPath:dsimportFile];

    // the File Handle got tucked away into the server object let's get the data out.
    NSData* buffer = [server.exportFile readDataToEndOfFile];

    // create a new file in this service's tempdir
    [[NSFileManager defaultManager] createFileAtPath: dsimportFile contents: buffer attributes: nil];
    [fh closeFile];
    
    
    NSTask* task = [[NSTask alloc] init];
    
    NSMutableArray* args = [NSMutableArray arrayWithArray:[NSArray arrayWithObjects:dsimportFile,@"/LDAPv3/127.0.0.1",@"I",@"--remoteusername",server.diradminName,@"--remotehost",server.serverName, nil]];
    
    if(user.userPreset){
        [args addObject:@"--userpreset"];
        [args addObject:user.userPreset];
    }
    
    [task setLaunchPath: @"/usr/bin/dsimport"];
    [task setArguments:args];
    
    //setup system pipes and filehandles to process output data
    
    NSPipe* outputPipe = [[NSPipe alloc] init];
    
    [task setStandardInput: [NSPipe pipe]];
    [task setStandardOutput:outputPipe];
    [task setStandardError:outputPipe]; // Get standard error output too
    
    [task launch];
    
    NSFileHandle* sendCmd = [[task standardInput] fileHandleForWriting];
    NSString* inString = [ NSString stringWithFormat: @"%@\n",server.diradminPass];
    
    NSData* data = [inString dataUsingEncoding:NSUTF8StringEncoding];
    
    // dsimport asks fot the password twice so we'll just repeat it here
    [sendCmd writeData:data];
    [sendCmd writeData:data];

    
    NSData* outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    NSString* outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

    return outputString;
}


-(void)eyeCandy{
    double z = 0.1;
    int i = 0;
    for (i=0; i < 1000; i++) {
        [[self.xpcConnection remoteObjectProxy] setProgress:z];
        doSleep(0.001)
    }

}

-(void)uploadToServer:(Server*)server
                 user:(User*)user
                withReply:(void (^)(NSString*,NSError* error))reply{
    NSError* error = nil;
    [[self.xpcConnection remoteObjectProxy] setProgressMsg:@"Adding users to server..."];
    
    NSString* msg = [self dsImport:user withServer:server];
    [self eyeCandy];
    reply(msg,error);
}

//---------------------------------
//  Singleton and ListenerDelegate
//---------------------------------

+ (Uploader*)sharedUploader {
    static dispatch_once_t onceToken;
    static Uploader* shared;
    dispatch_once(&onceToken, ^{
        shared = [Uploader new];
    });
    return shared;
}


/* Implement the one method in the NSXPCListenerDelegate protocol.*/
- (BOOL)listener:(NSXPCListener*)listener shouldAcceptNewConnection:(NSXPCConnection*)newConnection {
   
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Uploader)];
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    newConnection.exportedObject = self;
    
    self.xpcConnection = newConnection;
    [newConnection resume];
    
    return YES;
}


@end
