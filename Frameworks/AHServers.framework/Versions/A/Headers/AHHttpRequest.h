//
//  AHHttpRequest.h
//  Server
//
//  Created by Eldon on 12/18/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHHttpManager.h"

@interface AHHttpRequest : NSObject

+(NSData*)getDataFromServer:(NSString*)URL;
+(NSData*)getDataFromServer:(NSString*)URL error:(NSError**)error;

+(NSData*)getDataFromServer:(NSString*)URL user:(NSString*)user password:(NSString*)password;
+(NSData*)getDataFromServer:(NSString*)URL user:(NSString*)user password:(NSString*)password error:(NSError**)error;

+(NSData*)PostDataToServer:(NSString*)URL;
+(NSData*)PostDataToServer:(NSString*)URL error:(NSError**)error;

+(NSData*)PostDataToServer:(NSString*)URL user:(NSString*)user password:(NSString*)password;
+(NSData*)PostDataToServer:(NSString*)URL user:(NSString*)user password:(NSString*)password error:(NSError**)error;



+(BOOL)checkURL:(NSString*)URL __deprecated;
+(void)checkURL:(NSString*)URL status:(void(^)(BOOL avaliable))reply;

@end
