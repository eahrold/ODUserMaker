//
//  ODUNSXPC.h
//  ODUserMaker
//
//  Created by Eldon on 11/12/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Server,User,ODUController;

@interface ODUDSQuery : NSObject

+(BOOL)getAuthenticatedDirectoryNode:(Server*)server error:(NSError**)error;

+(void)getDSUserList;
+(void)getDSGroupList;
+(void)getDSUserPresets;

+(void)getSettingsForPreset:(NSString*)preset sender:(ODUController*)sender;

+(void)addUser:(User*)user toGroups:userGroups sender:(id)sender;

+(void)addUserList:(User*)user withGroups:(NSArray*)groups sender:(ODUController*)sender;
+(void)cancelUserImport:(ODUController*)sender;

+(void)resetPassword:(User*)user sender:(ODUController*)sender;

@end
