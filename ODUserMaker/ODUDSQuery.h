//
//  ODUNSXPC.h
//  ODUserMaker
//
//  Created by Eldon on 11/12/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Server;

@interface ODUDSQuery : NSObject

+(BOOL)getAuthenticatedDirectoryNode:(Server*)server error:(NSError**)error;

+(void)getDSUserList;
+(void)getDSGroupList;
+(void)getDSUserPresets;

@end
