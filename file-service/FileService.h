//
//  ExportFile.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "SecuredObjects.h"

#define kFileServiceName @"com.aapps.ODUserMaker.file-service"

@protocol Exporter
-(void)makeExportFile:(NSFileHandle*)sourceFile
            withReply:(void (^)(NSFileHandle *convertedFile))reply;

-(void)makeSingelUserFile:(User*)user
                withReply:(void (^)(NSString *convertedFile))reply;

@end



@interface Exporter : NSObject <NSXPCListenerDelegate, Exporter>
+ (Exporter *)sharedExporter;

@property (weak) NSXPCConnection *xpcConnection;

@end
