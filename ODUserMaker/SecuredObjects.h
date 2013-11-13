//
//  User.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *const kFileServiceName;
extern NSString *const kDirectoryServiceName;

@interface User : NSObject <NSSecureCoding>

-(NSDictionary*)makeDictFromUser;

@property (copy) NSString *userName;
@property (copy) NSString *firstName;
@property (copy) NSString *lastName;
@property (copy) NSString *userCWID;
@property (copy) NSString *userUUID;

@property (copy) NSString *primaryGroup;
@property (copy) NSString *emailDomain;
@property (copy) NSString *keyWord;
@property (copy) NSString *userPreset;

@property (copy) NSString *sharePoint;
@property (copy) NSString *sharePath;
@property (copy) NSString *nfsPath;
@property (copy) NSString *userShell;




@property (copy) NSString *userFilter;

//The User export file is the one we use for the the file-service
@property (copy) NSFileHandle *exportFile;
@property (copy) NSFileHandle *importFileHandle;
@property (copy) NSString *importFilePath;
@property (copy) NSURL *importFileURL;

@property (copy) NSArray *userList;
@property (copy) NSArray *groupList;
@property (copy) NSNumber *userCount;

@end


@interface Server : NSObject <NSSecureCoding>

@property (copy) NSString *serverName;
@property (copy) NSString *diradminName;
@property (copy) NSString *diradminPass;

//The Server export file is the one we use for the the network-service
@property (copy) NSFileHandle *exportFile;



@end