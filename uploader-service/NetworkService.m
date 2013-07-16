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
-(NSString*)doDsImportLocally:(User*)user withServer:(Server*)server;
-(void)eyeCandy;
@end


@implementation Uploader

-(NSString*)doDsImportLocally:(User*)user withServer:(Server*)server{
    NSLog(@"Doing Task");
    
    // Set up the actual stirngs
    NSString* ldpaAddress = [NSString stringWithFormat:@"/LDAPv3/%@",server.serverName];

    NSTask* task = [[NSTask alloc] init];
    NSArray* args = [NSArray arrayWithObjects:ldpaAddress,@"--username",server.diradminName, nil];
    
    //[task setLaunchPath: @"/usr/bin/dsimport"];
    [task setLaunchPath: @"/bin/echo"];

    [task setArguments:args];
    
    //setup system pipes and filehandles to process output data
    
    NSPipe* outputPipe = [[NSPipe alloc] init];
    
    [task setStandardInput: [NSPipe pipe]];
    [task setStandardOutput:outputPipe];
    [task setStandardError:outputPipe]; // Get standard error output too
    
    [task launch];
    
    NSFileHandle *sendCmd = [[task standardInput] fileHandleForWriting];
    NSString * inString = [ NSString stringWithFormat: @"%@\n",server.diradminPass];
    
    NSData *data = [inString dataUsingEncoding:NSUTF8StringEncoding];
    [sendCmd writeData:data];

    
    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

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
                 user:(User *)user
                withReply:(void (^)(NSString *))reply{
   
    [[self.xpcConnection remoteObjectProxy] setProgressMsg:@"Updateing progress..."];
    
    

    NSString* msg = [self doDsImportLocally:user withServer:server];
    [self eyeCandy];
    //NSString* msg = @"right back at you";
    reply(msg);
}

//---------------------------------
//  Singleton and ListenerDelegate
//---------------------------------

+ (Uploader *)sharedUploader {
    static dispatch_once_t onceToken;
    static Uploader *shared;
    dispatch_once(&onceToken, ^{
        shared = [Uploader new];
    });
    return shared;
}


// Implement the one method in the NSXPCListenerDelegate protocol.
- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
   
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Uploader)];
    newConnection.exportedObject = self;
    
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    self.xpcConnection = newConnection;
    
    [newConnection resume];
    
    return YES;
}


@end
