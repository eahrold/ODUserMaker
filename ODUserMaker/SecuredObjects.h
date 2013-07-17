//
//  User.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface User : NSObject <NSSecureCoding>

@property (copy) NSString *userName;
@property (copy) NSString *firstName;
@property (copy) NSString *lastName;
@property (copy) NSString *userCWID;
@property (copy) NSString *primaryGroup;
@property (copy) NSString *emailDomain;
@property (copy) NSString *keyWord;
@property (copy) NSString *userPreset;
@property (copy) NSString* importFile;
@property (copy) NSString* userFilter;





@end


@interface Server : NSObject <NSSecureCoding>

@property (copy) NSString *serverName;
@property (copy) NSString *diradminName;
@property (copy) NSString *diradminPass;
@property (copy) NSString* exportFile;


@end