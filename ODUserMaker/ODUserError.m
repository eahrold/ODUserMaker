//
//  ODUserError.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 8/31/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUserError.h"
#import <Cocoa/Cocoa.h>

//  The Domain to user with error codes and Alert Panel
NSString* const ODUMDomain = @"com.aapps.ODUserMaker";

@implementation ODUserError

+ (NSError*) errorWithCode:(int)code
{
    NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:[ODUserError errorTextForCode:code], NSLocalizedDescriptionKey, nil];
    return [self errorWithDomain:ODUMDomain code:code userInfo:info];
}

+ (NSError*) errorWithCode:(NSInteger)code message:(NSString*)msg
{
    NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:msg, NSLocalizedDescriptionKey, nil];
    return [self errorWithDomain:ODUMDomain code:code userInfo:info];
}

+ (NSString *) errorTextForCode:(int)code {
    NSString * codeText = @"";
    
    switch (code) {
        case ODUMReadFileError: codeText = @"There was a problem reading the import file.  Please make sure that it's located inside you home directory";
            break;
        case ODUMWriteFileError: codeText = @"There was a problem writing the DSimport file.  Please make sure you've chosen a location inside you home directory";
            break;
        case ODUMUserNotFound:codeText = @"A user with that name was not found on the server";
            break;
        case ODUMUserAlreadyExists:codeText = @"A user with that username already exists.";
            break;
        case ODUMCantAddUserToServer:codeText =  @"There were problems adding the user to the server.";
            break;
        case ODUMCantAddUserToGroup:codeText = @"We Couldn't add the user to the group.";
            break;
        case ODUMCantAddUserToServerOrGroup:codeText = @"We Couldn't add the user to server or update the the group.";
            break;
               case ODUMGroupNotFound:codeText = @"We couldn't find the group on the server";
            break;
        case ODUMPresetNotFound:codeText = @"We couldn't find that preset on the server";
            break;
        case ODUMCantConnectToNode:codeText = @"Unable to connect to Directory Server";
            break;
        case ODUMCantAuthenicate:codeText = @"Authentication failed to Directory Server";
            break;
        case ODUMNotAuthenticated:codeText = @"You are currently Not authenticated to the Directory Server, please check the supplied information";break;
        case ODUMFieldsMissing:codeText = @"Some fields are missing, please make sure everything is filled out";
            break;
        default: codeText = @"There was a unknown problem, sorry!"; break;
    }
    
    return codeText;
}


@end

