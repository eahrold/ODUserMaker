//
//  ExportFile.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "FileService.h"
#import "AppProgress.h"
#import <CommonCrypto/CommonDigest.h>

@implementation Exporter

//------------------------------------------------
//  Internal Methods
//------------------------------------------------

-(NSString*)makeUidFromUserName:(NSString*)uname{
    
    const char *cStr = [uname UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *md5 = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
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

-(void)writeUser:(User*)user toFile:(NSFileHandle*)fh{
    
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
    NSString* keyWords = @"";
    
    NSArray * uArray = [NSArray arrayWithObjects:userName,fullName,lastName,email,uuid,password,passwordPolicy,primaryGroup,nfsHome,homeDir,keyWords, nil];
    
    for (NSString __strong* i in uArray) {
        if (!i || [i isEqual:@""]){
            NSLog(@"%@ is blank",i);
            i = @"";
        }
        else{
            NSLog(@"all's ok with %@",i);
        }
    }
    
    NSString * userEntry = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@\n",userName,fullName,firstName,lastName,email,uuid,password,passwordPolicy,primaryGroup,nfsHome,homeDir,keyWords];
    [fh writeData:[userEntry dataUsingEncoding:NSUTF8StringEncoding]];

   }


//------------------------------------------------
//  NSXPC Methods
//------------------------------------------------


-(void)makeExportFile:(NSFileHandle*)convertedFile
            withReply:(void (^)(NSFileHandle *exportFile))reply{
    
}

-(void)makeSingelUserFile:(User*)user
                withReply:(void (^)(NSString *exportFile))reply{
    
    NSString* exportFile = [NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(),user.userName];
    [[NSFileManager defaultManager] createFileAtPath:exportFile contents:nil attributes:nil];
    NSFileHandle* fh = [NSFileHandle fileHandleForWritingAtPath:exportFile];
    
    [self writeHeaders:fh];
    [self writeUser:user toFile:fh];
    
    [fh closeFile];
    
    reply(exportFile);
    
}
//---------------------------------
//  Singleton and ListenerDelegate
//---------------------------------

+ (Exporter *)sharedExporter {
    static dispatch_once_t onceToken;
    static Exporter *shared;
    dispatch_once(&onceToken, ^{
        shared = [Exporter new];
    });
    return shared;
}


// Implement the one method in the NSXPCListenerDelegate protocol.
- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Exporter)];
    newConnection.exportedObject = self;
    
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    self.xpcConnection = newConnection;
    
    [newConnection resume];
    
    return YES;
}


@end

