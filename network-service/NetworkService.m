//
//  Uploader.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "NetworkService.h"

@implementation Uploader

-(void)uploadToServer:(Server*)server
                 user:(User*)user
            withReply:(void (^)(NSString* response,NSError* error))reply{
    
    NSError* error = nil;
    NSString* msg;
    
    if([user.userCount isEqualToNumber:[NSNumber numberWithInt:1]]){
        msg = [NSString stringWithFormat:@"Adding %@ to server...", user.userName];
    }else{
        msg =[NSString stringWithFormat:@"Adding %@ users to server...", user.userCount];
    }
    
    [[self.xpcConnection remoteObjectProxy] setProgressMsg:msg];
    
    NSString* response = [self dsImport:user withServer:server];
    reply(response,error);
}

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
    NSMutableArray* args;
    
    if([server.serverName isEqualToString:@"127.0.0.1"]){
       args = [NSMutableArray arrayWithArray:[NSArray arrayWithObjects:dsimportFile,@"/LDAPv3/127.0.0.1",@"I",@"--username",server.diradminName, nil]];
    }else{
        args = [NSMutableArray arrayWithArray:[NSArray arrayWithObjects:dsimportFile,@"/LDAPv3/127.0.0.1",@"I",@"--remoteusername",server.diradminName,@"--remotehost",server.serverName, nil]];
    }
    
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
    
    [sendCmd writeData:data];

    // if remotehost dsimport asks fot the password twice
    if(![server.serverName isEqualToString:@"127.0.0.1"]){
        [sendCmd writeData:data];
    }

    NSData* outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    NSString* outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

    return outputString;
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
