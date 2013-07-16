//
//  User.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "SecuredObjects.h"

@implementation User

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        // NSSecureCoding requires that we specify the class of the object while decoding it, using the decodeObjectOfClass:forKey: method.
        _userName = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"userName"];
        _firstName = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"firstName"];
        _lastName = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"lastName"];
        _userCWID = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"userCWID"];
        _primaryGroup = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"primaryGroup"];
        _emailDomain = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"emailDomain"];
        _keyWord = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"keyWord"];
        _userPreset = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"userPreset"];






    }
    return self;
}

// Because this class implements initWithCoder:, it must also return YES from this method.
+ (BOOL)supportsSecureCoding { return YES; }

- (void)encodeWithCoder:(NSCoder *)aEncoder {
    [aEncoder encodeObject:_userName forKey:@"userName"];
    [aEncoder encodeObject:_firstName forKey:@"firstName"];
    [aEncoder encodeObject:_lastName forKey:@"lastName"];
    [aEncoder encodeObject:_userCWID forKey:@"userCWID"];
    [aEncoder encodeObject:_primaryGroup forKey:@"primaryGroup"];
    [aEncoder encodeObject:_emailDomain forKey:@"emailDomain"];
    [aEncoder encodeObject:_keyWord forKey:@"keyWord"];
    [aEncoder encodeObject:_userPreset forKey:@"userPreset"];


}

@end

@implementation Server

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        // NSSecureCoding requires that we specify the class of the object while decoding it, using the decodeObjectOfClass:forKey: method.
        _serverName = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"serverName"];
        _diradminName = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"diradminName"];
        _diradminPass = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"diradminPass"];
        _exportFile = [aDecoder decodeObjectOfClass: [NSString class] forKey:@"exportFile"];
        
    }
    return self;
}

// Because this class implements initWithCoder:, it must also return YES from this method.
+ (BOOL)supportsSecureCoding { return YES; }

- (void)encodeWithCoder:(NSCoder *)aEncoder {
    [aEncoder encodeObject:_serverName forKey:@"serverName"];
    [aEncoder encodeObject:_diradminName forKey:@"diradminName"];
    [aEncoder encodeObject:_diradminPass forKey:@"diradminPass"];
    [aEncoder encodeObject:_exportFile forKey:@"exportFile"];

}


@end
