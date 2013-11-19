//
//  NSTextField+blankCheck.m
//  ODUserMaker
//
//  Created by Eldon on 11/18/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "NSTextField+blankCheck.h"

@implementation NSTextField (blankCheck)
-(NSString*)blankCheck{
    if([self.stringValue isEqualToString:@""])return nil;
    else return self.stringValue;
}
@end


@implementation NSString (blankCheck)
-(NSString*)blankCheck{
    if([self isEqualToString:@""])return nil;
    else return self;
}
@end
