//
//  ExportFile.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ODUser,ODRecordList;

@protocol FileService
-(void)makeMultiUserFile:(ODUser*)user
              importFile:(NSString*)file
              exportFile:(NSFileHandle*)exportFile
                  filter:(NSString*)filter
               withReply:(void (^)(NSError *error))reply;

-(void)makeUserArray:(ODUser*)user
          importFile:(NSString*)file
          exportFile:(NSFileHandle*)exportFile
              filter:(NSString*)filter
            andGroupList:(NSArray*)groups
               withReply:(void (^)(NSArray* groupList,ODRecordList* userlist,NSError *error))reply;

-(void)makePasswordResetListFromFile:(NSString*)file
                           usernameColumn:(NSInteger)userNameColumn
                           passwordColumn:(NSInteger)passWordColumn
                            reply:(void (^)(ODRecordList* userlist,NSError *error))reply;

@end


@interface FileService : NSObject <NSXPCListenerDelegate, FileService>
@property (weak) NSXPCConnection *xpcConnection;

@end
