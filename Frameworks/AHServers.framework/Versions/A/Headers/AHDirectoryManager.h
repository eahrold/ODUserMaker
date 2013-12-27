//
//  AHDirectoryManager.h
//  ODPasswordReset
//
//  Created by Eldon on 12/18/13.
//  Copyright (c) 2013 Loyola University New Orleans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHSecureObjects.h"
#import "AHDirectoryConstants.h"

@class AHDirectoryManager;

@protocol AHDirectoryDelegate <NSObject>
-(void)didRecieveQueryUpdate:(NSDictionary*)record;
-(void)didRecieveStatusUpdate:(OSStatus)status;
-(void)didAddRecord:(NSString*)record progress:(double)progress;
-(void)didAddUser:(NSString *)user toGroup:(NSString*)group progress:(double)progress;
@end

@interface AHDirectoryManager : NSObject{
}

+(AHDirectoryManager*)sharedManager;
@property (weak) id<AHDirectoryDelegate>delegate;
@property (copy,nonatomic) NSString *directoryServer;
@property (copy,nonatomic) NSString *diradmin;
@property (copy,nonatomic) NSString *diradminPassword;
@property (readwrite,nonatomic) int directoryDomain;
@property BOOL authenticated;

-(id)initWithDelegate:(id<AHDirectoryDelegate>)delegate;
-(id)initWithServer:(NSString *)server domain:(int)domain;
-(id)initWithServer:(NSString*)server;
-(id)initWithDomain:(int)domain;
-(id)initWithDefaultDomain;

-(OSStatus)authenticate;
-(OSStatus)authenticate:(NSError**)error;

-(BOOL)addUser:(ODUser*)user error:(NSError**)error;
-(void)addListOfUsers:(ODUserList*)users reply:(void(^)(NSError *error))reply;
-(void)cancelUserImport;

-(BOOL)addUser:(ODUser*)user withPreset:(NSString*)preset error:(NSError**)error;
-(void)addListOfUsers:(ODUserList*)users withPreset:(NSString*)preset reply:(void(^)(NSError *error))reply;

-(BOOL)removeUser:(NSString*)user error:(NSError**)error;
-(void)removeUsers:(NSArray*)users reply:(void(^)(NSError *error))reply;
-(void)cancelUserRemoval;

-(BOOL)addUser:(NSString*)user toGroup:(NSString*)group error:(NSError**)error;
-(BOOL)addUsers:(NSArray*)users toGroup:(NSString*)group error:(NSError**)error;

-(BOOL)removeUser:(NSString*)user fromGroup:(NSString*)group error:(NSError**)error;
-(BOOL)removeUsers:(NSArray*)users fromGroup:(NSString*)group error:(NSError**)error;

-(BOOL)addGroup:(ODGroup*)group error:(NSError*)error;
-(BOOL)addGroups:(ODGroupList*)groups error:(NSError*)error;

-(ODPreset*)settingsForPreset:(NSString*)preset;

-(BOOL)resetPassword:(NSString*)oldPassword toPassword:(NSString *)newPassword user:(NSString*)user;
-(BOOL)resetPassword:(NSString*)oldPassword toPassword:(NSString *)newPassword user:(NSString*)user error:(NSError **)error;

-(NSArray *)groupMembers:(NSString*)group;

-(void)userListWithDelegate:(id<AHDirectoryDelegate>)delegate;
-(void)presetListWithDelegate:(id<AHDirectoryDelegate>)delegate;
-(void)groupListWithDelegate:(id<AHDirectoryDelegate>)delegate;

-(void)userList:(void(^)(NSArray *array))reply;
-(void)presetList:(void(^)(NSArray *array))reply;
-(void)groupList:(void(^)(NSArray *array))reply;

-(NSArray*)avaliableLocalNodes;
-(BOOL)user:(NSString*)user isMemberOfGroup:(NSString *)group error:(NSError**)error;

-(BOOL)refreshNode;
-(BOOL)refreshNode:(NSError**)error;

@end
