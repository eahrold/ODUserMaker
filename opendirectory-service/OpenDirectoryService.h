//
//  OpenDirectoryService.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/21/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <OpenDirectory/OpenDirectory.h>
#import "ODUserBridge.h"


@protocol OpenDirectoryService

/* methods for editing users/group*/
-(void)addSingleUser:(User*)user toServer:(Server*)server andGroups:(NSArray*)groups withReply:(void (^)(NSError *error))reply;

-(void)addListOfUsers:(NSArray*)list usingPresetsIn:(User*)user toServer:(Server*)server andGroups:(NSArray*)userGroups withReply:(void (^)(NSError *error))reply;


-(void)resetUserPassword:(User*)user onServer:(Server*)server
               withReply:(void (^)(NSError *error))reply;


/* methods for getting lists*/ 

-(void)getUserPresets:(Server*)server
            withReply:(void (^)(NSArray *userPreset,NSError *error))reply;

-(void)getSettingsForPreset:(NSString*)preset
                 withServer:(Server*)server
            withReply:(void (^)(NSDictionary *settings,NSError *error))reply;

-(void)getGroupListFromServer:(Server*)server
                    withReply:(void (^)(NSArray *groupList,NSError *error))reply;

-(void)getUserListFromServer:(Server*)server
                   withReply:(void (^)(NSArray *userList,NSError *error))reply;


/* methods for status checking */

-(void)checkServerStatus:(Server*)server
               withReply:(void (^)(OSStatus connected))reply;


@end


@interface OpenDirectoryService : NSObject <NSXPCListenerDelegate, OpenDirectoryService>
+ (OpenDirectoryService *)sharedDirectoryServer;
@property (weak) NSXPCConnection *xpcConnection;

@end
