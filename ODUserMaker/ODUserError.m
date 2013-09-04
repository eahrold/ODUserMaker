//
//  ODUserError.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 8/31/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUserError.h"


@implementation ODUserError

+ (NSError*) errorWithCode:(NSInteger)code message:(NSString*)msg
{
    NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:msg, NSLocalizedDescriptionKey, nil];
    return [self errorWithDomain:ODUMDomain code:code userInfo:info];
}

@end
