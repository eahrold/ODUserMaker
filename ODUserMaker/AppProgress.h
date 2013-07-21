//
//  AppProgress.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#define doSleep(fmt, ...)  [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow: fmt, ##__VA_ARGS__]];

#define kReadFileErrorMsg @"There was a problem reading the import file.  Please make sure that it's located inside you home directory"
#define kWriteFileErrorMsg @"There was a problem writing the DSimport file.  Please make sure you've chosen a location inside you home directory"


//Used by NSXPC services to send progress updates back to the main app

@protocol Progress
- (void)setProgress:(double)progress;
- (void)setProgress:(double)progress withMessage:(NSString*)message;
- (void)setProgressMsg:(NSString*)message;
@end
