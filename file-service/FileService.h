//
//  ExportFile.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ODUserBridge.h"


@protocol FileService
-(void)makeMultiUserFile:(User*)user withReply:(void (^)(NSError *error))reply;

-(void)makeUserArray:(User*)user
            andGroupList:(NSArray*)groups
               withReply:(void (^)(NSArray* groupList,NSArray* userlist,NSError *error))reply;

@end


@interface FileService : NSObject <NSXPCListenerDelegate, FileService>
+ (FileService *)sharedFileService;

@property (weak) NSXPCConnection *xpcConnection;

@end
