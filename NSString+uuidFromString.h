//
//  NSString+uuidFromString.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 9/1/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

@interface NSString (uuidFromString)
-(NSString*)uuidFromString;

@end
