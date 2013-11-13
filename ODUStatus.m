//
//  ODUStatus.m
//  ODUserMaker
//
//  Created by Eldon on 11/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUStatus.h"

@implementation ODUStatus

+ (ODUStatus *)sharedStatus {
    static dispatch_once_t onceToken;
    static ODUStatus *shared;
    dispatch_once(&onceToken, ^{
        shared = [ODUStatus new];
    });
    return shared;
}

@end
