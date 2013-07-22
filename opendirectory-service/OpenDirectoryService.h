//
//  OpenDirectoryService.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/21/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "SecuredObjects.h"

#define kDirectoryServiceName @"com.aapps.ODUserMaker.opendirectory-service"

@protocol DirectoryServer
-(void)getUserPresets:(Server*)server
            withReply:(void (^)(NSArray *userPreset,NSError *error))reply;

-(void)checkServerStatus:(NSString*)server
               withReply:(void (^)(BOOL connected))reply;


@end


@interface DirectoryServer : NSObject <NSXPCListenerDelegate, DirectoryServer>
+ (DirectoryServer *)sharedDirectoryServer;

@property (weak) NSXPCConnection *xpcConnection;

@end
