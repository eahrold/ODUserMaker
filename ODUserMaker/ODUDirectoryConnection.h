//
//  ODUSingleUser.h
//  ODUserMaker
//
//  Created by Eldon on 11/19/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ODSecureObjects.h"

@class ODUDirectoryConnection;

@protocol ODUSQueryDelegate <NSObject>
-(NSString*)nameOfPreset;
-(void)didGetDSUserList:(NSArray*)dsusers;
-(void)didGetDSGroupList:(NSArray*)dsgroups;
-(void)didGetDSUserPresets:(NSArray*)dspresets;
-(void)didGetSettingsForPreset:(ODPreset*)settings;
@end

@protocol ODUAuthenticatorDelegate <NSObject>
-(NSString*)nameOfServer;
-(NSString*)nameOfDiradmin;
-(NSString*)passwordForDiradmin;
-(void)didRecieveStatusUpdate:(OSStatus)status message:(NSString*)message;
-(void)didGetPassWordFromKeychain:(NSString*)password;
@end

@interface ODUDirectoryConnection : NSXPCConnection

@property (weak) id<ODUSQueryDelegate>queryDelegate;
@property (weak) id<ODUAuthenticatorDelegate>authDelegate;

-(id)initConnection;
-(id)initWithQueryDelegate:(id<ODUSQueryDelegate>)delegate;
-(id)initWithAuthDelegate:(id<ODUAuthenticatorDelegate>)delegate;

-(void)addUser:(ODUser*)user andGroups:(NSArray*)groups reply:(void (^)(NSError *error))reply;
-(void)importUserList:(ODRecordList*)users withGroups:(NSArray*)groups reply:(void (^)(NSError *))reply;

-(void)resetPassword:(ODUser*)user reply:(void (^)(NSError *error))reply;
-(void)resetPasswords:(ODRecordList*)users reply:(void (^)(NSError *error))reply;

-(void)deleteUser:(NSString*)user reply:(void (^)(NSError *error))reply;

-(void)addUser:(NSString*)user toGroup:(NSString *)group reply:(void (^)(NSError *))reply;
-(void)removeUser:(NSString*)user fromGroup:(NSString *)group reply:(void (^)(NSError *))reply;

-(void)checkServerStatus;
-(void)getSettingsForPreset;

+(void)cancelImport;
+(void)getUserList:(id<ODUSQueryDelegate>)delegate;
+(void)getGroupList:(id<ODUSQueryDelegate>)delegate;
+(void)getPresetList:(id<ODUSQueryDelegate>)delegate;

@end
