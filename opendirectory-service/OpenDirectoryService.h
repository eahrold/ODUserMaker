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

@protocol OpenDirectoryService
-(void)checkCredentials:(Server*)server withReply:(void (^)(BOOL authenticated))reply;

-(void)resetUserPassword:(User*)user onServer:(Server*)server
               withReply:(void (^)(NSError *error))reply;

-(void)getUserPresets:(Server*)server
            withReply:(void (^)(NSArray *userPreset,NSError *error))reply;

-(void)getGroupListFromServer:(Server*)server
                    withReply:(void (^)(NSArray *groupList,NSError *error))reply;

-(void)getUserListFromServer:(Server*)server
                   withReply:(void (^)(NSArray *userList,NSError *error))reply;

-(void)checkServerStatus:(NSString*)server
               withReply:(void (^)(BOOL connected))reply;

-(void)addUser:(User*)user
       toGroup:(NSArray*)group
      toServer:(Server*)server
     withReply:(void (^)(NSError * error))reply;

-(void)addGroups:(NSArray*)groups toServer:(Server*)server withReply:(void (^)(NSError * error))reply;;

@end


@interface OpenDirectoryService : NSObject <NSXPCListenerDelegate, OpenDirectoryService>
+ (OpenDirectoryService *)sharedDirectoryServer;

@property (weak) NSXPCConnection *xpcConnection;

@end
