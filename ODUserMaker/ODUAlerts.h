//
//  ODUAlerts.h
//  ODUserMaker
//
//  Created by Eldon on 11/12/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ODUError.h"

@interface ODUAlerts : NSObject
+ (void)showErrorAlert:(NSError *)error;
+ (void)showAlert:(NSString *)alert withDescription:(NSString *)msg;
@end
