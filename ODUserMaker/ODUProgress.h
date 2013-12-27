//
//  AppProgress.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>

//Used by NSXPC services to send progress updates back to the main app
static NSString *const kFileServiceName = @"com.aapps.ODUserMaker.file-service";
static NSString *const kDirectoryServiceName = @"com.aapps.ODUserMaker.opendirectory-service";

@protocol Progress
- (void)setProgress:(double)progress;
- (void)setProgress:(double)progress withMessage:(NSString*)message;
- (void)setProgressMsg:(NSString*)message;
- (void)gotStatusUpdate:(OSStatus)status;
- (void)gotUserRecord:(NSString*)user;
@end
