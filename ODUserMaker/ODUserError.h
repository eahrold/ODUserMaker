//
//  ODUserError.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 8/31/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//
#import <Foundation/Foundation.h>

/* set up domain */
extern NSString* const ODUMDomain;

@interface ODUserError : NSError
+ (NSError*) errorWithCode:(int)code;
+ (NSError*) errorWithCode:(NSInteger)rc message:(NSString*)msg;

@end

enum ODUMErrorCodes {
    ODUMSuccess = 0,
    
    ODUMReadFileError = 1001 ,
    ODUMWriteFileError = 1002 ,
    
    ODUMUserNotFound = 2001,
    ODUMUserAlreadyExists = 2002,
    
    ODUMCantAddUserToServer = 2003,
    ODUMCantAddUserToGroup = 2004,
    ODUMCantAddUserToServerOrGroup = 2005,
    
    ODUMGroupNotFound = 3001,
    ODUMPresetNotFound = 3002,
    
    ODUMCantConnectToNode = 4001,
    ODUMCantAuthenicate = 4002,
    ODUMNotAuthenticated = 4003,
};


