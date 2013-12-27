//
//  NSString+uuidFromString.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 9/1/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "NSString+uuidFromString.h"

@implementation NSString (uuidFromString)
-(NSString*)uuidFromString{
    /*This makes a 5 digit user ID based on the user name*/
    const char* cStr = [self UTF8String];
    unsigned char digest[16];
    
    CC_MD5( cStr, (int)strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString* md5 = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH* 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [md5 appendFormat:@"%02x", digest[i]];
    
    
    NSString* noLetters = [[md5 componentsSeparatedByCharactersInSet:
                            [[NSCharacterSet decimalDigitCharacterSet]
                             invertedSet]] componentsJoinedByString:@""];
    
    NSString* noZeros = [noLetters stringByReplacingOccurrencesOfString:@"0" withString:@""];
    NSString* uuid = [noZeros substringFromIndex:[noZeros length]-6];
    
    return  uuid;
}
@end
