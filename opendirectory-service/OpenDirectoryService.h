//
//  OpenDirectoryService.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/21/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenDirectory/OpenDirectory.h>
@class ODUser,ODServer,ODUserList,ODPreset;

@protocol OpenDirectoryService

/* methods for editing users/group*/
-(void)addSingleUser:(ODUser*)user withGroups:(NSArray*)groups withReply:(void (^)(NSError *error))reply;

-(void)addListOfUsers:(ODUserList*)users withGroups:(NSArray*)groups withReply:(void (^)(NSError *error))reply;

-(void)resetUserPassword:(ODUser*)user withReply:(void (^)(NSError *error))reply;


/* methods for getting lists*/ 
-(void)getPresetsListFromServer:(void (^)(NSArray *presetList,NSError *error))reply;

-(void)getGroupListFromServer:(void (^)(NSArray *groupList,NSError *error))reply;

-(void)getUserListFromServer:(void (^)(NSArray *userList,NSError *error))reply;
-(void)getUserListAsync:(void (^)(NSError *error))reply;

-(void)getSettingsForPreset:(NSString*)preset
                  withReply:(void (^)(ODPreset *preset,NSError *error))reply;

/* methods for status checking */
-(void)checkServerStatus:(ODServer*)server
               withReply:(void (^)(OSStatus connected))reply;

/* method to cancel import*/
-(void)cancelImportStatus:(void (^)(BOOL connected))reply;

@end


@interface OpenDirectoryService : NSObject <NSXPCListenerDelegate, OpenDirectoryService>{
    void (^replyBlock)(NSError *error);
}

+ (OpenDirectoryService *)sharedDirectoryServer;
@property (weak) NSXPCConnection *xpcConnection;
@property (strong,nonatomic) void (^DSReplyBlock)(NSArray* array,NSError *error);

@end

