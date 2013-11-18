//
//  ODUPasswordReset.h
//  ODUserMaker
//
//  Created by Eldon on 11/18/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ODUController,User;

@interface ODUPasswordReset : NSObject
-(void)resetPassword:(ODUController*)sender;
@property (copy) NSString* userName;
@property (copy) NSString* NewPassword;
@property BOOL changed;
@end
