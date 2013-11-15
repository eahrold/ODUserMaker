//
//  ExportFile.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "FileService.h"
#import "NSString+StringSanitizer.h"

@implementation FileService


//------------------------------------------------
//  DSImport File Creation
//------------------------------------------------

-(void)makeMultiUserFile:(User*)user
               withReply:(void (^)(NSError*error))reply{
    
    NSError* error = nil;
    NSArray* ulist = nil;

    static int userCounter = 0;
    
    [self writeHeaders:user.exportFile];
    
    if(![self parseUserList:user toFile:user.exportFile gettingCount:&userCounter andArray:&ulist]){
        [ODUserError errorWithCode:ODUMWriteFileError];
    }
    
    reply(error);
}

//------------------------------------------------
//  Multi User Array 
//------------------------------------------------

-(void)makeUserArray:(User*)user
                andGroupList:(NSArray*)groups
                   withReply:(void (^)(NSArray* dsgroups,NSArray* userlist,NSError *error))reply{
    
    NSError* error = nil;
    NSArray* dsgroups = nil;
    NSArray* ulist = nil;

    static int userCounter = 0;

    if(![self parseUserList:user toFile:user.exportFile gettingCount:&userCounter andArray:&ulist]){
        [ODUserError errorWithCode:ODUMReadFileError];
        goto nsxpc_return;
    }
    
    dsgroups = [self makeGroups:groups withUserArray:user.userList usingFilter:user.userFilter];

nsxpc_return:
    reply(dsgroups,ulist,error);
    
}

-(BOOL)parseUserList:(User*)user toFile:(NSFileHandle*)fh gettingCount:(int*)uc andArray:(NSArray**)ulist{
    *uc = 0;
    NSMutableArray* returnArray = [NSMutableArray new];
    
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
    
    NSArray* tmpArray1;
    NSArray* tmpArray2;
    NSMutableSet* processed = [NSMutableSet set];
    
    for (NSString* u in user.userList) {
        if ([u rangeOfString:user.userFilter].location != NSNotFound){
            @try{
                tmpArray1 = [u componentsSeparatedByString:@"\t"];
                if ([processed containsObject:[tmpArray1 objectAtIndex:0]] == NO) {
                    *uc = *uc + 1;
                    
                    /* add the object to the processed array */
                    [processed addObject:[tmpArray1 objectAtIndex:0]];
                    
                    /* set up a new user to add */
                    User* tmpUser = [User new];
                    tmpUser.userName = [NSString stringWithFormat:@"%@",[tmpArray1 objectAtIndex:0]];
                    tmpUser.userCWID = [NSString stringWithFormat:@"%@",[tmpArray1 objectAtIndex:2]];
                    
                    /* break it up one more time. */
                    NSString* rawName = [NSString stringWithFormat:@"%@",[tmpArray1 objectAtIndex:1]];
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
                    if(fh)[self writeUser:tmpUser toFile:fh];
                    [returnArray addObject:[tmpUser makeDictFromUser]];
                    
                    /* send updates back to the UI */
                    //[[self.xpcConnection remoteObjectProxy] setProgress:progress];
                }
            }
            @catch (NSException* exception) {
            }
        }
    }
    
    if(ulist)*ulist = returnArray;
    return YES;
}



-(NSArray*)makeGroups:(NSArray*)groups
        withUserArray:(NSArray*)users
          usingFilter:(NSString*)filter{
    /* this takes the array of groups/match specified in the main window and then using the users
     from the array set in the parseList method it creates an array of dictionaries of the groups
     and the users that are in them based on the match.  There has to be a better way but this works*/
    
    [[self.xpcConnection remoteObjectProxy] setProgressMsg:@"Determining Group Membership..."];

    
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
