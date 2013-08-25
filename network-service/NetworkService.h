//
//  Uploader.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "SecuredObjects.h"

#define kUploaderServiceName @"com.aapps.ODUserMaker.network-service"

@protocol Uploader
-(void)uploadToServer:(Server*)server
                 user:(User*)user
            withReply:(void (^)(NSString* response,NSError* error))reply;
@end


@interface Uploader : NSObject <NSXPCListenerDelegate, Uploader>
+ (Uploader *)sharedUploader;

@property (weak) NSXPCConnection *xpcConnection;

@end
