//
//  ODUserError.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 8/31/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//
#import <Foundation/Foundation.h>

#define SET_ERROR(rc, msg...)\
error = [ODUserError errorWithCode:rc message:[NSString stringWithFormat:@"%@",msg]];\

/* set up domain */
extern NSString* const ODUMDomain;

@interface ODUserError : NSError
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
};




/* define some error messages */
extern NSString* const ODUMReadFileErrorMsg;
extern NSString* const ODUMWriteFileErrorMsg;

extern NSString* const ODUMUserNotFoundMsg;
extern NSString* const ODUMUserAlreadyExistsMsg;

extern NSString* const ODUMCantAddUserToServerMSG;
extern NSString* const ODUMCantAddUserToGroupMSG;
extern NSString* const ODUMCantAddUserToServerOrGroupMSG;

extern NSString* const ODUMGroupNotFoundMsg;
extern NSString* const ODUMPresetNotFoundMsg;

extern NSString* const ODUMCantConnectToNodeMsg;
extern NSString* const ODUMCantAuthenicateMsg;


