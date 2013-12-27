//
//  NSTextField+fieldIsBlank.h
//  ODUserMaker
//
//  Created by Eldon on 11/18/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSTextField (isNotBlank)
-(BOOL)isBlank;
-(BOOL)isNotBlank;
@end

@interface NSString (isNotBlank)
-(BOOL)isBlank;
-(BOOL)isNotBlank;
@end

@interface NSTextField (blankIsNil)
-(NSString*)blankIsNil;
@end

@interface NSString (blankIsNil)
-(NSString*)blankIsNil;
@end

@interface NSArray (requiredFields)
-(BOOL)requiredFields;
@end