//
//  ODUFileParser.h
//  ODUserMaker
//
//  Created by Eldon on 4/14/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ODUser,ODRecordList;

@interface ODUFileParser : NSObject

-(void)makeMultiUserFile:(ODUser*)user
              importFile:(NSString*)importFile
              exportFile:(NSFileHandle*)exportFile
                  filter:(NSString*)filter
               withReply:(void (^)(NSError *error))reply;

-(void)makeUserArray:(ODUser*)user
          importFile:(NSString*)importFile
          exportFile:(NSFileHandle*)exportFile
              filter:(NSString*)filter
        andGroupList:(NSArray*)groups
           withReply:(void (^)(NSArray* groupList,ODRecordList* userlist,NSError *error))reply;

-(void)makePasswordResetListFromFile:(NSString*)file
                      usernameColumn:(NSInteger)userNameColumn
                      passwordColumn:(NSInteger)passWordColumn
                               reply:(void (^)(ODRecordList* userlist,NSError *error))reply;
@end
