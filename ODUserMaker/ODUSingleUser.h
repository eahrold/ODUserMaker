//
//  ODUSingleUser.h
//  ODUserMaker
//
//  Created by Eldon on 11/19/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
@class User;

@interface ODUSingleUser : NSObject
-(id)initWithUser:(User*)user andGroups:(NSArray*)groups;
-(void)addUser:(void (^)(NSError *error))replyBlock;

@property (strong) User* user;
@property (strong) NSArray* groups;

@end
