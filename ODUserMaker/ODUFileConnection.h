//
//  ODUFileConnection.h
//  ODUserMaker
//
//  Created by Eldon on 12/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ODUser,ODUserList;

@interface ODUFileConnection : NSXPCConnection
-(id)initConnection;

-(void)makeUserList:(void (^)(ODUserList* users, NSArray* groups,NSError *error))reply;

@property (weak,nonatomic) ODUser   *user;
@property (weak,nonatomic) NSArray  *groups;
@property (weak,nonatomic) NSString *filter;
@property (weak,nonatomic) NSString *inFile;
@property (weak,nonatomic) NSFileHandle *outFile;
@end
