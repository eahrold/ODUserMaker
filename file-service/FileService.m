//
//  ExportFile.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "FileService.h"
#import "AppProgress.h"
#import "NSString+StringSanitizer.h"
#import <CommonCrypto/CommonDigest.h>

@implementation Exporter

//------------------------------------------------
//  Internal Methods
//------------------------------------------------


-(NSString*)makeUidFromUserName:(NSString*)uname{
    
    const char* cStr = [uname UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString* md5 = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH* 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [md5 appendFormat:@"%02x", digest[i]];
    
    
    NSString* noLetters = [[md5 componentsSeparatedByCharactersInSet:
                            [[NSCharacterSet decimalDigitCharacterSet]
                             invertedSet]] componentsJoinedByString:@""];
    
    NSString* noZeros = [noLetters stringByReplacingOccurrencesOfString:@"0" withString:@""];

    NSString* uuid = [noZeros substringFromIndex:[noZeros length]-5];

    return uuid;
}

-(NSString*)setPasswordPoilcy{
    NSString* pwp = @"isDisabled=0 isAdminUser=0 newPasswordRequired=1 usingHistory=0 canModifyPasswordforSelf=1 usingExpirationDate=0 usingHardExpirationDate=0 requiresAlpha=0 requiresNumeric=0 expirationDateGMT=0 hardExpireDateGMT=0 maxMinutesUntilChangePassword=0 maxMinutesUntilDisabled=0 maxMinutesOfNonUse=0 maxFailedLoginAttempts=0 minChars=0 maxChars=0 passwordCannotBeName=0 validAfter=0 requiresMixedCase=0 requiresSymbol=0 notGuessablePattern=0 isSessionKeyAgent=0 isComputerAccount=0 adminClass=0 adminNoChangePasswords=0 adminNoSetPolicies=0 adminNoCreate=0 adminNoDelete=0 adminNoClearState=0 adminNoPromoteAdmins=0";
    return pwp;
}

-(void)writeHeaders:(NSFileHandle*)fh{
    NSString* odHeader = @"0x0A 0x5C 0x3A 0x2C dsRecTypeStandard:Users 12 dsAttrTypeStandard:RecordName dsAttrTypeStandard:RealName dsAttrTypeStandard:FirstName dsAttrTypeStandard:LastName dsAttrTypeStandard:EMailAddress dsAttrTypeStandard:UniqueID dsAttrTypeStandard:Password dsAttrTypeStandard:PasswordPolicyOptions dsAttrTypeStandard:PrimaryGroupID dsAttrTypeStandard:NFSHomeDirectory dsAttrTypeStandard:HomeDirectory dsAttrTypeStandard:Keywords\n";
        
    [fh writeData:[odHeader dataUsingEncoding:NSUTF8StringEncoding]];
}

-(BOOL)writeUser:(User*)user toFile:(NSFileHandle*)fh{
    
    // Set up the actual elements we'll need 
    NSString* userName = user.userName;
    NSString* fullName = [NSString stringWithFormat:@"%@ %@",user.firstName, user.lastName];
    NSString* firstName = user.firstName;
    NSString* lastName = user.lastName;
    NSString* email = [NSString stringWithFormat:@"%@@%@",user.userName,user.emailDomain];
    NSString* uuid = [self makeUidFromUserName:userName];
    NSString* password = user.userCWID;
    NSString* passwordPolicy = [self setPasswordPoilcy];
    NSString* primaryGroup = user.primaryGroup;
    NSString* nfsHome = @"";
    NSString* homeDir = @"";
    NSString* keyWords = user.keyWord;
    
    NSArray* uArray = [NSArray arrayWithObjects:userName,fullName,lastName,email,uuid,password,passwordPolicy,primaryGroup,nfsHome,homeDir,keyWords, nil];
    
    for (NSString __strong* i in uArray) {
        if (!i || [i isEqual:@" "]){
            i = @"";
        }
        else{
        }
    }
    
    NSString* userEntry = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@\n",userName,fullName,firstName,lastName,email,uuid,password,passwordPolicy,primaryGroup,nfsHome,homeDir,keyWords];
    @try{
    [fh writeData:[userEntry dataUsingEncoding:NSUTF8StringEncoding]];
    }
    @catch(NSException* exception){
        return NO;
    }
    return YES;
   }

-(BOOL)parseUserList:(User*)user toFile:(NSFileHandle*)fh{
    NSData* importFileData = [user.importFileHandle readDataToEndOfFile];
    user.userList = [[NSString alloc] initWithData:importFileData
                                          encoding:NSUTF8StringEncoding];
    

    
    
    // split up the string by new line char and though unnecissary alphabetize them.
    NSArray* arr = [user.userList componentsSeparatedByString:@"\n"];
    arr = [arr sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    if( arr == nil || [arr count] == 0 || [arr count] == 1 ){
        return NO;
    }
    
    // set up the chunk of progress size for indicator upadates...
    //double totalSize = [userArray count];
    //double progress = 100 / totalSize;
   
    NSArray* tmpArray;
    NSArray* tmpArray2;
    NSMutableSet* processed = [NSMutableSet set];
    
    for (NSString* item in arr) {
        if ([item rangeOfString:user.userFilter].location != NSNotFound){
            @try{
                tmpArray = [item componentsSeparatedByString:@"\t"];
                if ([processed containsObject:[tmpArray objectAtIndex:0]] == NO) {
                    
                    // add the object to the processed array
                    [processed addObject:[tmpArray objectAtIndex:0]];
                    
                    // set up a new user to add
                    User* tmpUser = [User new];
                    tmpUser.userName = [NSString stringWithFormat:@"%@",[tmpArray objectAtIndex:0]];
                    tmpUser.userCWID = [NSString stringWithFormat:@"%@",[tmpArray objectAtIndex:2]];
                    
                    // break it up one more time...
                    NSString* rawName = [NSString stringWithFormat:@"%@",[tmpArray objectAtIndex:1]];
                    tmpArray2 = [rawName componentsSeparatedByString:@","];
                    NSString* firstName = [NSString stringWithFormat:@"%@",[tmpArray2 objectAtIndex:1]];
                    NSString* lastName = [NSString stringWithFormat:@"%@",[tmpArray2 objectAtIndex:0]];
                    
                    //Sanatize...
                    firstName = [firstName stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    lastName = [lastName stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    tmpUser.firstName = [firstName stringByTrimmingLeadingWhitespace];
                    tmpUser.lastName = [lastName stringByTrimmingLeadingWhitespace];
                    
                    // get the items from the User object sent over by the main app...
                    tmpUser.primaryGroup = user.primaryGroup;
                    tmpUser.emailDomain = user.emailDomain;
                    tmpUser.keyWord = user.keyWord;
                    
                    // then write it to the file...
                    [self writeUser:tmpUser toFile:fh];
                    
                    //[[self.xpcConnection remoteObjectProxy] setProgress:progress];
                    }
            }
        @catch (NSException* err) {
            }
        }
    }
     return YES;
}

//------------------------------------------------
//  NSXPC Methods
//------------------------------------------------


-(void)makeExportFile:(User*)user
            withReply:(void (^)(NSError*error,NSString* msg))reply{
    BOOL success;
    NSString* msg;
    NSError* error = nil;
    
    [[self.xpcConnection remoteObjectProxy] setProgress:0 withMessage:@"Adding Users..."];
    
    [self writeHeaders:user.exportFile];

    success = [self parseUserList:user toFile:user.exportFile];
    
    if(success){
        msg = @"Made user list";
    }else{
        NSMutableDictionary* noList = [NSMutableDictionary dictionary];
        [noList setValue:@"We couldn't create user list" forKey:NSLocalizedDescriptionKey];
        error =[NSError errorWithDomain:@"fault" code:101 userInfo:noList];
    }
    
    [user.exportFile closeFile];
    reply(error,msg);

    
}

-(void)makeSingelUserFile:(User*)user
                withReply:(void (^)(NSError* error,NSString* msg))reply{
    BOOL success;
    NSString* msg;
    NSError* error = nil;
    
    [[self.xpcConnection remoteObjectProxy] setProgress:50 withMessage:@"Adding User..."];

    [self writeHeaders:user.exportFile];
    success = [self writeUser:user toFile:user.exportFile];
    
    if(success){
        msg = @"made user";
    }else{
        NSMutableDictionary* noUser = [NSMutableDictionary dictionary];
        [noUser setValue:@"We couldn't create user" forKey:NSLocalizedDescriptionKey];
        error =[NSError errorWithDomain:@"fault" code:101 userInfo:noUser];
    }
    
    
    [user.exportFile closeFile];
    reply(error,msg);
    
}
//---------------------------------
//  Singleton and ListenerDelegate
//---------------------------------

+ (Exporter* )sharedExporter {
    static dispatch_once_t onceToken;
    static Exporter* shared;
    dispatch_once(&onceToken, ^{
        shared = [Exporter new];
    });
    return shared;
}


// Implement the one method in the NSXPCListenerDelegate protocol.
- (BOOL)listener:(NSXPCListener* )listener shouldAcceptNewConnection:(NSXPCConnection* )newConnection {
    
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Exporter)];
    newConnection.exportedObject = self;
    
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    self.xpcConnection = newConnection;
    
    [newConnection resume];
    
    return YES;
}


@end
