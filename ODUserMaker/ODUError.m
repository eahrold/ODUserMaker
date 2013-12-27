//
//  ODUserError.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 8/31/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUError.h"

//  The Domain to user with error codes and Alert Panel
NSString* const ODUMDomain = @"com.aapps.ODUserMaker";
NSString* const ODUMReadFileErrorMSG = @"There was a problem reading the import file.  Please make sure that it's located inside you home directory";
NSString* const ODUMWriteFileErrorMSG = @"There was a problem writing the DSimport file.  Please make sure you've chosen a location inside you home directory";
NSString* const ODUMNoUsersInFileMSG = @"The File dose not contain any users (or is not formatted correctly)";
NSString* const ODUMNoFileSelectedMSG =@"You must choose a file first";
NSString* const ODUMUserNotFoundMSG = @"A user with that name was not found on the server";
NSString* const ODUMUserAlreadyExistsMSG =@"A user with that username already exists.";
NSString* const ODUMCantAddUserToServerMSG=@"There were problems adding the user to the server.";
NSString* const ODUMCantAddUserToGroupMSG= @"We Couldn't add the user to the group.";
NSString* const ODUMCantAddUserToServerOrGroupMGS=@"We Couldn't add the user to server or update the the group.";
NSString* const ODUMGroupNotFoundMSG=@"We couldn't find the group on the server";
NSString* const ODUMPresetNotFoundMSG=@"We couldn't find that preset on the server";
NSString* const ODUMCantConnectToNodeMSG=@"Unable to connect to Directory Server";
NSString* const ODUMCantAuthenicateMSG= @"Authentication failed to Directory Server";
NSString* const ODUMNotAuthenticatedMSG=@"You are currently Not authenticated to the Directory Server, please check the supplied information";
NSString* const ODUMFieldsMissingMSG= @"Some fields are missing, please make sure everything is filled out";
NSString* const ODUMGenericErrorMSG=@"There was a unknown problem, sorry!";


// Server Status Codes
NSString* const ODUNoNodeMSG = @"Could Not Contact Server";
NSString* const ODUUnauthenticatedLocalMSG =@"Could Not Authenticate to Local Directory Server";
NSString* const ODUUnauthenticatedProxyMSG =@"Could Not Authenticate to Directory Server Remotley";
NSString* const ODUAuthenticatedLocalMSG =@"The the username and password are correct, connected locally.";
NSString* const ODUAuthenticatedProxyMSG =@"The the username and password are correct, connected over proxy";



@implementation ODUError

+ (NSError*) errorWithCode:(int)code
{
    NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:[ODUError errorTextForCode:code], NSLocalizedDescriptionKey, nil];
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
        case ODUMReadFileError:codeText = ODUMReadFileErrorMSG;
            break;
        case ODUMWriteFileError:codeText = ODUMWriteFileErrorMSG;
            break;
        case ODUMNoUsersInFile:codeText = ODUMNoUsersInFileMSG;
            break;
        case ODUMNoFileSelected:codeText = ODUMNoFileSelectedMSG;
            break;
        case ODUMUserNotFound:codeText = ODUMUserNotFoundMSG;
            break;
        case ODUMUserAlreadyExists:codeText = ODUMUserAlreadyExistsMSG;
            break;
        case ODUMCantAddUserToServer:codeText = ODUMCantAddUserToServerMSG;
            break;
        case ODUMCantAddUserToGroup:codeText = ODUMCantAddUserToGroupMSG;
            break;
        case ODUMCantAddUserToServerOrGroup:codeText = ODUMCantAddUserToServerOrGroupMGS;
            break;
        case ODUMGroupNotFound:codeText = ODUMGroupNotFoundMSG;
            break;
        case ODUMPresetNotFound:codeText = ODUMPresetNotFoundMSG;
            break;
        case ODUMCantConnectToNode:codeText = ODUMCantConnectToNodeMSG;
            break;
        case ODUMCantAuthenicate:codeText = ODUMCantAuthenicateMSG;
            break;
        case ODUMNotAuthenticated:codeText = ODUMNotAuthenticatedMSG;
            break;
        case ODUMFieldsMissing:codeText = ODUMFieldsMissingMSG;
            break;
        default: codeText = ODUMGenericErrorMSG;
            break;
    }
    
    return codeText;
}


@end

