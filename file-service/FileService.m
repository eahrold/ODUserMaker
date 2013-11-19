//
//  ExportFile.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "FileService.h"
#import "NSString+StringSanitizer.h"
#import "NSString+uuidFromString.h"

@implementation FileService{
    NSArray* rawUserList;
}


//------------------------------------------------
//  DSImport File Creation
//------------------------------------------------

-(void)makeMultiUserFile:(User*)user
               withReply:(void (^)(NSError*error))reply{
    
    NSError* error;
    [self parseUserList:user error:&error];
    
    reply(error);
}

//------------------------------------------------
//  Multi User Array 
//------------------------------------------------

-(void)makeUserArray:(User*)user
                andGroupList:(NSArray*)groups
                   withReply:(void (^)(NSArray* groupList,NSArray* userlist,NSError *error))reply{
    
    NSError* error;
    NSArray* groupList;

    if(![self parseUserList:user error:&error]){
        error = [ODUError errorWithCode:ODUMReadFileError];
        goto nsxpc_return;
    }
    
    groupList = [self makeGroups:groups usingFilter:user.userFilter];
nsxpc_return:
    reply(groupList,user.userList,error);
    
}

-(BOOL)parseUserList:(User*)user error:(NSError *__autoreleasing*)error{
    NSMutableArray* returnArray = [NSMutableArray new];
    
    
    NSData* importFileData = [user.importFileHandle readDataToEndOfFile];
    
    if(!importFileData){
        if(error)*error = [ODUError errorWithCode:ODUMReadFileError];
        return NO;
    }
    
    [self writeHeaders:user.exportFile];

    NSString* str = [[NSString alloc] initWithData:importFileData
                                          encoding:NSUTF8StringEncoding];
    
    
    /* split up the string by new line char and though unnecissary alphabetize them.*/
    rawUserList = [str componentsSeparatedByString:@"\n"];
    [rawUserList sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    if( rawUserList == nil || [rawUserList count] <= 1 ){
        if(error)*error = [ODUError errorWithCode:ODUMNoUsersInFile];
        return NO;
    }
    
    NSArray* tmpArray1;
    NSArray* tmpArray2;
    NSMutableSet* processed = [NSMutableSet set];
    
    for (NSString* u in rawUserList) {
        if ([u rangeOfString:user.userFilter].location != NSNotFound){
            @try{
                tmpArray1 = [u componentsSeparatedByString:@"\t"];
                if ([processed containsObject:[tmpArray1 objectAtIndex:0]] == NO) {
                    
                    /* add the object to the processed array */
                    [processed addObject:tmpArray1[0]];
                    
                    /* set up a new user to add */
                    User* tmpUser = [User new];
                    tmpUser.userName = tmpArray1[0];
                    tmpUser.userCWID = tmpArray1[2];
                    
                    /* break it up one more time. */
                    NSString* rawName = tmpArray1[1];

                    //NSString* rawName = [NSString stringWithFormat:@"%@",[tmpArray1 objectAtIndex:1]];
                    tmpArray2 = [rawName componentsSeparatedByString:@","];
                    NSString* firstName = tmpArray2[1];
                    NSString* lastName = tmpArray2[0];
                    
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
                    if(user.exportFile)[self writeUser:tmpUser toFile:user.exportFile];
                    [returnArray addObject:[tmpUser makeDictFromUser]];
                }
            }
            @catch (NSException* exception) {
            }
        }
    }
    
    user.userList = [NSArray arrayWithArray:returnArray];
    return YES;
}



-(NSArray*)makeGroups:(NSArray*)groups
          usingFilter:(NSString*)filter{
    /* this takes the array of groups/match specified in the main window and then using the users
     from the array set in the parseList method it creates an array of dictionaries of the groups
     and the users that are in them based on the match.  There has to be a better way but this works*/
    
    NSArray* returnArray;
    if(!rawUserList){
        return nil;
    }
    
    [[self.xpcConnection remoteObjectProxy] setProgressMsg:@"Determining Group Membership..."];

    NSMutableSet* groupProcessed = [[NSMutableSet alloc]init];
    NSMutableArray* mArray = [[NSMutableArray alloc]init];

    
    NSMutableDictionary* groupDict;
    NSMutableSet* userProcessed;
    NSMutableArray* userArray;
    
    NSString* groupName = nil;
    BOOL isSameGroup = NO;
    
    for(NSDictionary* g in groups){
        if (![groupName isEqualToString:[g objectForKey:@"group"]]){
            groupDict = [NSMutableDictionary new];
            groupName = [g objectForKey:@"group"];
            isSameGroup = NO;
        }else{
            isSameGroup = YES;
        }
        
        NSString* matchName = [g objectForKey:@"match"];
        
        if ([groupProcessed containsObject:groupName] == NO){
            userArray = [NSMutableArray new];
            userProcessed = [NSMutableSet new];
            [groupProcessed addObject:groupName];
        }
        
        for(NSString *u in rawUserList){
            if ([u rangeOfString:filter].location != NSNotFound){
                if ([u rangeOfString:matchName options:NSCaseInsensitiveSearch].location != NSNotFound){
                    NSString *uname = [u componentsSeparatedByString:@"\t"][0];
                    
                    if ([userProcessed containsObject:uname] == NO){
                        [userArray addObject:uname];
                    }
                    [userProcessed addObject:uname];
                }
            }
        }
        
        [groupDict setObject:userArray forKey:@"users"];
        [groupDict setObject:groupName forKey:@"group"];
        if(isSameGroup){
            [mArray removeLastObject];
        }
        [mArray addObject:groupDict];
    }
    
    returnArray = mArray;
    return returnArray;
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
    
    if(user.userUUID){
        uuid = user.userUUID;
    }else{
        uuid = [userName uuidFromString];
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
