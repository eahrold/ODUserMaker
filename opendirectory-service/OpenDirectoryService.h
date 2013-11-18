//
//  OpenDirectoryService.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/21/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenDirectory/OpenDirectory.h>
#import "ODUserBridge.h"


@protocol OpenDirectoryService

/* methods for editing users/group*/
-(void)addSingleUser:(User*)user andGroups:(NSArray*)groups withReply:(void (^)(NSError *error))reply;
-(void)addListOfUsers:(User*)user withReply:(void (^)(NSError *error))reply;
-(void)resetUserPassword:(User*)user withReply:(void (^)(NSError *error))reply;


/* methods for getting lists*/ 
-(void)getUserPresets:(void (^)(NSArray *userPreset,NSError *error))reply;

-(void)getSettingsForPreset:(NSString*)preset
                  withReply:(void (^)(NSDictionary *settings,NSError *error))reply;

-(void)getGroupListFromServer:(void (^)(NSArray *groupList,NSError *error))reply;

-(void)getUserListFromServer:(void (^)(NSArray *userList,NSError *error))reply;


/* methods for status checking */
-(void)checkServerStatus:(Server*)server
               withReply:(void (^)(OSStatus connected))reply;

/* method to cancel import*/
-(void)cancelImportStatus:(void (^)(OSStatus connected))reply;

@end


@interface OpenDirectoryService : NSObject <NSXPCListenerDelegate, OpenDirectoryService, ODQueryDelegate>{
    void (^replyBlock)(NSError *error);
    void (^DSReplyBlock)(NSArray* array,NSError *error);
}

+ (OpenDirectoryService *)sharedDirectoryServer;
@property (weak) NSXPCConnection *xpcConnection;

@end

enum ODServerStatusCodes {
    // here are the status returns
    ODUNoNode = -1, // No Node,
    ODUUnauthenticatedLocal = -2,// -2 locally connected, but wrong password
    ODUUnauthenticatedProxy = -3,// -3 proxy but wrong auth password
    ODUAuthenticatedLocal = 0,// 0 Authenticated locally
    ODUAuthenticatedProxy = 1,// 1 Authenticated over proxy
};
