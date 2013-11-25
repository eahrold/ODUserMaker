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
#import <DHlibxls/DHxlsReader.h>

@implementation FileService{
    NSMutableArray* rawUserList;
    NSArray* internalUserList;
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
        goto nsxpc_return;
    }
    
    groupList = [self makeGroups:groups usingFilter:user.userFilter];
nsxpc_return:
    reply(groupList,internalUserList,error);
    
}

-(BOOL)parseUserList:(User*)user error:(NSError *__autoreleasing*)error{
    NSMutableArray* returnArray = [NSMutableArray new];
    
    if(user.exportFile){
        [self writeHeaders:user.exportFile];
    }
    
    DHxlsReader* reader =[DHxlsReader xlsReaderWithPath:user.importFilePath];
    if(!reader){
        if(error)*error = [ODUError errorWithCode:ODUMReadFileError];
        return NO;
    }
    
    [reader startIterator:0];
    int rows = [reader numberOfRowsInSheet:0];

    if( rows <= 1 ){
        if(error)*error = [ODUError errorWithCode:ODUMNoUsersInFile];
        return NO;
    }
    
    NSMutableSet* processed = [NSMutableSet set];
    
    
    for(int i = 1;i < rows+1;i++ ) {
        NSString* classNumber = [[reader cellInWorkSheetIndex:1 row:i col:4] str];
        NSString* userName = [[reader cellInWorkSheetIndex:1 row:i col:1] str];
        
        if([classNumber rangeOfString:user.userFilter options:NSCaseInsensitiveSearch].location != NSNotFound||
           [user.userFilter isEqualToString:@""])
        {
            // the rawUserList is what is used for making groups...
            if(!rawUserList)rawUserList = [[NSMutableArray alloc]init];
            [rawUserList addObject:[NSString stringWithFormat:@"%@:%@",userName,classNumber]];

            if ([processed containsObject:userName] == NO) {
                [processed addObject:userName];
                @try{
                    
                    User* tmpUser = [User new];
                    tmpUser.userName = userName;
                    NSString* rawName = [[reader cellInWorkSheetIndex:1 row:i col:2] str];

                    NSArray* rawNameArray = [rawName componentsSeparatedByString:@","];
                    
                    tmpUser.userCWID = [[reader cellInWorkSheetIndex:1 row:i col:3] str];

                    tmpUser.firstName = rawNameArray[1];
                    tmpUser.lastName = rawNameArray[0];
                    
                    tmpUser.firstName = [[rawNameArray[1] stringByReplacingOccurrencesOfString:@"\"" withString:@""]stringByTrimmingLeadingWhitespace];
                    tmpUser.lastName = [[rawNameArray[0] stringByReplacingOccurrencesOfString:@"\"" withString:@""]stringByTrimmingLeadingWhitespace];
                    
                    tmpUser.primaryGroup = user.primaryGroup;
                    tmpUser.emailDomain = user.emailDomain;
                    tmpUser.keyWord = user.keyWord;
                    
                    /* then write it to the file */
                    if(user.exportFile)[self writeUser:tmpUser toFile:user.exportFile];
                    [returnArray addObject:[tmpUser makeDictFromUser]];
                    
                }
                @catch (NSException* exception) {
                }
            }
        }
    }

    internalUserList = [NSArray arrayWithArray:returnArray];
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
    
    [rawUserList sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    [[self.xpcConnection remoteObjectProxy] setProgressMsg:@"Determining Group Membership..."];

    NSMutableSet* groupProcessed = [[NSMutableSet alloc]init];
    NSMutableArray* mArray = [[NSMutableArray alloc]init];

    
    NSMutableDictionary* groupDict;
    NSMutableSet* userProcessed;
    NSMutableArray* userArray;
    
    NSString* groupName;
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
            if ([u rangeOfString:matchName options:NSCaseInsensitiveSearch].location != NSNotFound){
                NSString *uname = [u componentsSeparatedByString:@":"][0];
                
                if ([userProcessed containsObject:uname] == NO){
                    [userArray addObject:uname];
                }
                [userProcessed addObject:uname];
            }
        }
        
        if(userArray)[groupDict setObject:userArray forKey:@"users"];
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
