//
//  User.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "SecuredObjects.h"

NSString *const kFileServiceName = @"com.aapps.ODUserMaker.file-service";
NSString *const kDirectoryServiceName = @"com.aapps.ODUserMaker.opendirectory-service";

@implementation User

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super init];
    if (self) {
        // NSSecureCoding requires that we specify the class of the object while decoding it, using the decodeObjectOfClass:forKey: method.
        _userName = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"userName"];
        _firstName = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"firstName"];
        _lastName = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"lastName"];
        _userCWID = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"userCWID"];
        _userUUID = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"userUUID"];
        
        _primaryGroup = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"primaryGroup"];
        _emailDomain = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"emailDomain"];
        _keyWord = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"keyWord"];
        
        _userPreset = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"userPreset"];
        _userShell = [aDecoder decodeObjectOfClass: [NSString class] forKey:@"userShell"];
        _sharePoint = [aDecoder decodeObjectOfClass: [NSString class] forKey:@"sharePoint"];
        _sharePath = [aDecoder decodeObjectOfClass: [NSString class] forKey:@"sharePath"];
        _nfsPath = [aDecoder decodeObjectOfClass: [NSString class] forKey:@"nfsPath"];
        
        _userFilter = [aDecoder decodeObjectOfClass: [NSString class] forKey:@"userFilter"];
        
        _userList = [aDecoder decodeObjectOfClass: [NSArray class] forKey:@"userList"];
        _groupList = [aDecoder decodeObjectOfClass: [NSArray class] forKey:@"groupList"];
        _userCount = [aDecoder decodeObjectOfClass: [NSNumber class] forKey:@"userCount"];
        
        _exportFile = [aDecoder decodeObjectOfClass: [NSFileHandle class] forKey:@"exportFile"];
        _importFileHandle = [aDecoder decodeObjectOfClass: [NSFileHandle class] forKey:@"importFileHandle"];
       
        _importFilePath = [aDecoder decodeObjectOfClass: [NSString class] forKey:@"importFilePath"];
        _importFileURL = [aDecoder decodeObjectOfClass: [NSURL class] forKey:@"importFileURL"];
    }
    return self;
}

// Because this class implements initWithCoder:, it must also return YES from this method.
+ (BOOL)supportsSecureCoding { return YES; }

- (void)encodeWithCoder:(NSCoder*)aEncoder {
    [aEncoder encodeObject:_userName forKey:@"userName"];
    [aEncoder encodeObject:_firstName forKey:@"firstName"];
    [aEncoder encodeObject:_lastName forKey:@"lastName"];
    [aEncoder encodeObject:_userCWID forKey:@"userCWID"];
    [aEncoder encodeObject:_userUUID forKey:@"userUUID"];

    [aEncoder encodeObject:_primaryGroup forKey:@"primaryGroup"];
    [aEncoder encodeObject:_emailDomain forKey:@"emailDomain"];
    
    [aEncoder encodeObject:_userShell forKey:@"userShell"];
    [aEncoder encodeObject:_sharePoint forKey:@"sharePoint"];
    [aEncoder encodeObject:_sharePath forKey:@"sharePath"];
    [aEncoder encodeObject:_nfsPath forKey:@"nfsPath"];


    [aEncoder encodeObject:_keyWord forKey:@"keyWord"];
    [aEncoder encodeObject:_userPreset forKey:@"userPreset"];
    
    [aEncoder encodeObject:_userList forKey:@"userList"];
    [aEncoder encodeObject:_userCount forKey:@"userCount"];

    [aEncoder encodeObject:_groupList forKey:@"groupList"];

    [aEncoder encodeObject:_userFilter forKey:@"userFilter"];
    
    [aEncoder encodeObject:_exportFile forKey:@"exportFile"];
    [aEncoder encodeObject:_importFileHandle forKey:@"importFileHandle"];
    [aEncoder encodeObject:_importFilePath forKey:@"importFilePath"];
    [aEncoder encodeObject:_importFileURL forKey:@"importFileURL"];
}

+(NSDictionary*)makeDictFromUser:(User*)user{
    NSMutableDictionary* dict =[NSMutableDictionary dictionaryWithCapacity:4];
    [dict setObject:user.userName forKey:@"userName" ];
    [dict setObject:user.firstName forKey:@"firstName" ];
    [dict setObject:user.lastName forKey:@"lastName" ];
    [dict setObject:user.userCWID forKey:@"userCWID" ];
    
    return [NSDictionary dictionaryWithDictionary:dict];
}

@end

@implementation Server

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super init];
    if (self) {
        // NSSecureCoding requires that we specify the class of the object while decoding it, using the decodeObjectOfClass:forKey: method.
        _serverName = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"serverName"];
        _diradminName = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"diradminName"];
        _diradminPass = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"diradminPass"];
        _exportFile = [aDecoder decodeObjectOfClass: [NSFileHandle class] forKey:@"exportFile"];
    }
    return self;
}

// Because this class implements initWithCoder:, it must also return YES from this method.
+ (BOOL)supportsSecureCoding { return YES; }

- (void)encodeWithCoder:(NSCoder*)aEncoder {
    [aEncoder encodeObject:_serverName forKey:@"serverName"];
    [aEncoder encodeObject:_diradminName forKey:@"diradminName"];
    [aEncoder encodeObject:_diradminPass forKey:@"diradminPass"];
    [aEncoder encodeObject:_exportFile forKey:@"exportFile"];
}


@end
