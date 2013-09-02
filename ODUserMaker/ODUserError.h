//
//  ODUserError.h
//  ODUserMaker
//
//  Created by Eldon Ahrold on 8/31/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//
#import <Foundation/Foundation.h>


@interface ODUserError : NSError
+ (NSError*) errorWithCode:(NSInteger)rc message:(NSString*)msg;

@end

#define SET_ERROR(rc, msg...)\
NSString* m = [NSString stringWithFormat:msg];\
error = [ODUserError errorWithCode:rc message:m];\



/* define some error messages */
#define ODUMReadFileErrorMsg @"There was a problem reading the import file.  Please make sure that it's located inside you home directory",

#define ODUMWriteFileErrorMsg @"There was a problem writing the DSimport file.  Please make sure you've chosen a location inside you home directory"

#define ODUMUserNotFoundMsg @"No user with that name was found on the server"
#define ODUMGroupNotFoundMsg @"Couldn't locate the group record on this server"
#define ODUMPresetNotFoundMsg @"No preset with that name was found on the server"

#define ODUMCantConnectToNodeMsg @"Couldn't connect to the Directory Server"
#define ODUMCantAuthenicateMsg @"Couldn't authenticate to the Directory Server with username and password"

#define ODUMUserAlreadyExistsMsg @"A user with that User Name already exists."
#define ODUMCantAddUserToGroupMSG @"We Couldn't add the user to the group."

