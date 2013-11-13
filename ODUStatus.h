//
//  ODUStatus.h
//  ODUserMaker
//
//  Created by Eldon on 11/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ODUStatus : NSObject

+(ODUStatus *)sharedStatus;

@property OSStatus serverStatus;

@property (strong) NSArray* userList;
@property (strong) NSArray* groupList;
@property (strong) NSArray* presetList;

@end
