//
//  ExportFile.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "FileService.h"


@implementation FileService

//------------------------------------------------
//  Single User Creation
//------------------------------------------------

-(void)makeSingelUserFile:(User*)user
                withReply:(void (^)(NSError* error))reply{
    BOOL success;
    NSError* error = nil;
    
    [self writeHeaders:user.exportFile];
    success = [self writeUser:user toFile:user.exportFile];
    
    if(!success){
        SET_ERROR(1, ODUMWriteFileErrorMsg);
    }
    
    
    [user.exportFile closeFile];
    reply(error);
    
}

//------------------------------------------------
//  Multi User Creation
//------------------------------------------------

-(void)makeMultiUserFile:(User*)user
            andGroupList:(NSArray*)groups
               withReply:(void (^)(NSArray* dsgroup,NSNumber* ucount,NSError*error))reply{
    BOOL success;
    NSError* error = nil;
    NSArray* dsgroups = nil;
    NSNumber* ucount = nil;
    NSMutableArray* ulist = [NSMutableArray new];
    
    
    [self writeHeaders:user.exportFile];
    
    success = [self parseUserList:user toFile:user.exportFile getArray:&ulist];
    dsgroups = [self makeGroups:groups withUserArray:user.userList usingFilter:user.userFilter];
    
    if(!success){
        error =[NSError errorWithDomain:NSPOSIXErrorDomain
                                   code:kReadFailureErr
                               userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                         ODUMWriteFileErrorMsg,
                                         NSLocalizedDescriptionKey,
                                         nil]];
    }
    ucount = [NSNumber numberWithInteger:ulist.count];
    [user.exportFile closeFile];
    reply(dsgroups,ucount,error);
    
    
}


-(BOOL)parseUserList:(User*)user toFile:(NSFileHandle*)fh getArray:(NSMutableArray**)ulist{
    [[self.xpcConnection remoteObjectProxy] setProgressMsg:@"Making Users List..."];

    NSData* importFileData = [user.importFileHandle readDataToEndOfFile];
    NSString* str = [[NSString alloc] initWithData:importFileData
                                          encoding:NSUTF8StringEncoding];
    
    
    
    /* split up the string by new line char and though unnecissary alphabetize them.*/
    user.userList = [str componentsSeparatedByString:@"\n"];
    [user.userList sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    if( user.userList == nil || [user.userList count] <= 1 ){
        return NO;
    }
    
    /* set up the chunk of progress size for indicator upadates...*/
    //double totalSize = [userArray count];
    //double progress = 100 / totalSize;
    
    NSArray* tmpArray;
    NSArray* tmpArray2;
    NSMutableSet* processed = [NSMutableSet set];
    
    for (NSString* u in user.userList) {
        if ([u rangeOfString:user.userFilter].location != NSNotFound){
            @try{
                tmpArray = [u componentsSeparatedByString:@"\t"];
                if ([processed containsObject:[tmpArray objectAtIndex:0]] == NO) {
                    [*ulist addObject:u];

                    /* add the object to the processed array */
                    [processed addObject:[tmpArray objectAtIndex:0]];
                    
                    /* set up a new user to add */
                    User* tmpUser = [User new];
                    tmpUser.userName = [NSString stringWithFormat:@"%@",[tmpArray objectAtIndex:0]];
                    tmpUser.userCWID = [NSString stringWithFormat:@"%@",[tmpArray objectAtIndex:2]];
                    
                    /* break it up one more time. */
                    NSString* rawName = [NSString stringWithFormat:@"%@",[tmpArray objectAtIndex:1]];
                    tmpArray2 = [rawName componentsSeparatedByString:@","];
                    NSString* firstName = [NSString stringWithFormat:@"%@",[tmpArray2 objectAtIndex:1]];
                    NSString* lastName = [NSString stringWithFormat:@"%@",[tmpArray2 objectAtIndex:0]];
                    
                    /* Sanatize */
                    firstName = [firstName stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    lastName = [lastName stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    tmpUser.firstName = [firstName stringByTrimmingLeadingWhitespace];
                    tmpUser.lastName = [lastName stringByTrimmingLeadingWhitespace];
                    
                    /* get the items from the User object sent over by the main app */
                    tmpUser.primaryGroup = user.primaryGroup;
                    tmpUser.emailDomain = user.emailDomain;
                    tmpUser.keyWord = user.keyWord;
                    
                    /* then write it to the file */
                    [self writeUser:tmpUser toFile:fh];
                    
                    /* send updates back to the UI */
                    //[[self.xpcConnection remoteObjectProxy] setProgress:progress];
                }
            }
            @catch (NSException* exception) {
            }
        }
    }
    return YES;
}



-(NSArray*)makeGroups:(NSArray*)groups
        withUserArray:(NSArray*)users
          usingFilter:(NSString*)filter{
    /* this takes the array of groups/match specified in the main window and then using the users
     from the array set in the parseList method it creates an array of dictionaries of the groups
     and the users that are in them based on the match.  There has to be a better way but this works*/
    
    [[self.xpcConnection remoteObjectProxy] setProgressMsg:@"Checking group Membership..."];

    
    NSMutableDictionary* groupDict = [[NSMutableDictionary alloc]init];
    NSMutableSet* groupProcessed = [[NSMutableSet alloc]init];
    NSMutableSet* userProcessed;
    
    NSMutableArray* mArray = [[NSMutableArray alloc]init];
    NSMutableArray* userSet = [[NSMutableArray alloc]init];
    
    NSString* groupName = nil;
    BOOL isSameGroup = NO;
    
    for(NSDictionary* g in groups){
        if (![groupName isEqualToString:[g objectForKey:@"group"]]){
            groupDict = [[NSMutableDictionary alloc]init];
            groupName = [g objectForKey:@"group"];
            isSameGroup = NO;
        }else{
            isSameGroup = YES;
        }
        
        NSString* matchName = [g objectForKey:@"match"];
        
        if ([groupProcessed containsObject:groupName] == NO){
            userSet = [[NSMutableArray alloc]init];
            userProcessed = [[NSMutableSet alloc]init];
            [groupProcessed addObject:groupName];
        }
        
        for(NSString *u in users){
            if ([u rangeOfString:filter].location != NSNotFound){
                if ([u rangeOfString:matchName options:NSCaseInsensitiveSearch].location != NSNotFound){
                    NSString *uname = [[u componentsSeparatedByString:@"\t"]objectAtIndex:0];
                    
                    if ([userProcessed containsObject:uname] == NO){
                        [userSet addObject:uname];
                    }
                    [userProcessed addObject:uname];
                }
            }
        }
        [groupDict setObject:userSet forKey:@"users"];
        [groupDict setObject:groupName forKey:@"group"];
        if(isSameGroup){
            [mArray removeLastObject];
        }
        [mArray addObject:groupDict];
    }
    
    NSArray *arr = [NSArray arrayWithArray:mArray];
    return arr;
}


//------------------------------------------------
//  Common Items
//------------------------------------------------


-(BOOL)writeUser:(User*)user toFile:(NSFileHandle*)fh{
    /* Set up the actual elements we'll need */
    NSString* userName = user.userName;
    NSString* fullName = [NSString stringWithFormat:@"%@ %@",user.firstName, user.lastName];
    NSString* firstName = user.firstName;
    NSString* lastName = user.lastName;
    NSString* email = [NSString stringWithFormat:@"%@@%@",user.userName,user.emailDomain];
    NSString* uuid;
    
    if(user.uuid){
        uuid = user.uuid;
    }else{
        uuid = [self makeUidFromUserName:userName];
    }
    
    NSString* password = user.userCWID;
    NSString* passwordPolicy = [self setPasswordPoilcy];
    NSString* primaryGroup = user.primaryGroup;
    NSString* nfsHome = @"";
    NSString* homeDir = @"";
    NSString* keyWords = user.keyWord;
    
    /* make the full string that we'll write out */
    NSString* userEntry = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@\n",userName,fullName,firstName,lastName,email,uuid,password,passwordPolicy,primaryGroup,nfsHome,homeDir,keyWords];
    
    @try{
        [fh writeData:[userEntry dataUsingEncoding:NSUTF8StringEncoding]];
    }@catch(NSException* exception){
        return NO;
    }
    return YES;
}



-(NSString*)setPasswordPoilcy{
    NSString* pwp = @"isDisabled=0 isAdminUser=0 newPasswordRequired=1 usingHistory=0 canModifyPasswordforSelf=1 usingExpirationDate=0 usingHardExpirationDate=0 requiresAlpha=0 requiresNumeric=0 expirationDateGMT=0 hardExpireDateGMT=0 maxMinutesUntilChangePassword=0 maxMinutesUntilDisabled=0 maxMinutesOfNonUse=0 maxFailedLoginAttempts=0 minChars=0 maxChars=0 passwordCannotBeName=0 validAfter=0 requiresMixedCase=0 requiresSymbol=0 notGuessablePattern=0 isSessionKeyAgent=0 isComputerAccount=0 adminClass=0 adminNoChangePasswords=0 adminNoSetPolicies=0 adminNoCreate=0 adminNoDelete=0 adminNoClearState=0 adminNoPromoteAdmins=0";
    return pwp;
}

-(void)writeHeaders:(NSFileHandle*)fh{
    NSString* odHeader = @"0x0A 0x5C 0x3A 0x2C dsRecTypeStandard:Users 12 dsAttrTypeStandard:RecordName dsAttrTypeStandard:RealName dsAttrTypeStandard:FirstName dsAttrTypeStandard:LastName dsAttrTypeStandard:EMailAddress dsAttrTypeStandard:UniqueID dsAttrTypeStandard:Password dsAttrTypeStandard:PasswordPolicyOptions dsAttrTypeStandard:PrimaryGroupID dsAttrTypeStandard:NFSHomeDirectory dsAttrTypeStandard:HomeDirectory dsAttrTypeStandard:Keywords\n";
    
    [fh writeData:[odHeader dataUsingEncoding:NSUTF8StringEncoding]];
}

-(NSString*)makeUidFromUserName:(NSString*)uname{
    /*This makes a 5 digit user ID based on the user name*/
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
    NSString* uuid = [noZeros substringFromIndex:[noZeros length]-6];
    
    return uuid;
}


//---------------------------------
//  Singleton and ListenerDelegate
//---------------------------------

+ (FileService* )sharedFileService {
    static dispatch_once_t onceToken;
    static FileService* shared;
    dispatch_once(&onceToken, ^{
        shared = [FileService new];
    });
    return shared;
}


/* Implement the one method in the NSXPCListenerDelegate protocol. */
- (BOOL)listener:(NSXPCListener* )listener shouldAcceptNewConnection:(NSXPCConnection* )newConnection {
    
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(FileService)];
    newConnection.exportedObject = self;
    
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    self.xpcConnection = newConnection;
    
    [newConnection resume];
    
    return YES;
}


@end
