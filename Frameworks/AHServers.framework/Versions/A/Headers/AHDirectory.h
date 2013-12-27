//
//  PROpenDirectory.h
//  ODPasswordReset
//
//  Created by Eldon on 12/14/13.
//  Copyright (c) 2013 Loyola University New Orleans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHDirectoryManager.h"

@interface AHDirectory : NSObject

+(BOOL)resetPassword:(NSString*)oldPassword newPassword:(NSString*)newPassword forUser:(NSString*)user;
+(BOOL)resetPassword:(NSString*)oldPassword newPassword:(NSString*)newPassword forUser:(NSString*)user error:(NSError **)error;

+(BOOL)addUser:(NSString*)user toGroup:(NSString*)group admin:(NSString*)admin password:(NSString*)password;
+(BOOL)addUser:(NSString*)user toGroup:(NSString*)group admin:(NSString*)admin password:(NSString*)password error:(NSError**)error;

+(NSArray*)avaliableLocalNodes;
+(NSArray*)groupMembers:(NSString*)group;
+(BOOL)user:(NSString*)user isMemberOfGroup:(NSString*)group;




@end
