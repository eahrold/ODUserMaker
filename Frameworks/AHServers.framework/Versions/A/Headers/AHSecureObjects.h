//
//  AHSecureObjects.h
//  Server
//
//  Created by Eldon on 12/18/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum{
    kAHNodeAuthenticatedLocal    =  1,
    kAHNodeAuthenticatedProxy    =  2,
    kAHNodeNotSet                =  0,
    kAHNodeNotAuthenticatedLocal = -1,
    kAHNodeNotAutenticatedProxy  = -2,
}AHDirectoryAuthenticationStatus;

#pragma mark - User
@interface ODUser : NSObject <NSSecureCoding>
@property (copy) NSString *userName;
@property (copy) NSString *firstName;
@property (copy) NSString *lastName;
@property (copy) NSString *passWord;
@property (copy) NSString *uuid;

@property (copy) NSString *primaryGroup;
@property (copy) NSString *emailDomain;
@property (copy) NSString *keyWord;
@property (copy) NSString *userPreset;

@property (copy) NSString *sharePoint;
@property (copy) NSString *sharePath;
@property (copy) NSString *nfsPath;
@property (copy,nonatomic) NSString *homeDirectory;

@property (copy) NSString *userShell;
@end

#pragma mark - UserList
@interface ODUserList : NSObject <NSSecureCoding>
@property (copy) NSArray *list;
@property (copy) NSArray *filter;
@end

#pragma mark - Group
@interface ODGroup : NSObject <NSSecureCoding>
@property (copy) NSString *groupName;
@property (copy) NSString *fullName;
@property (copy) NSString *guid;
@property (copy) NSString *owner;
@end

#pragma mark - Preset
@interface ODPreset : NSObject <NSSecureCoding>
@property (copy) NSString *presetName;
@property (copy) NSString *userShell;
@property (copy) NSString *nfsPath;
@property (copy) NSString *sharePath;
@property (copy) NSString *sharePoint;
@property (copy) NSString *primaryGroup;
@property (copy) NSString *mcxFlags;
@property (copy) NSString *mcxSettings;
@end

#pragma mark - GroupList
@interface ODGroupList : NSObject <NSSecureCoding>
@property (copy) NSArray *groups;
@end

#pragma mark - Server
@interface ODServer : NSObject <NSSecureCoding>
@property (copy) NSString *directoryServer;
@property (copy) NSString *directoryDomain;
@property (copy) NSString *diradminName;
@property (copy) NSString *diradminPass;
@end
