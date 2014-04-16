//
//  ODUFileParser.m
//  ODUserMaker
//
//  Created by Eldon on 4/14/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import "ODUFileParser.h"
#import "ODUDelegate.h"
#import <DHlibxls/DHxlsReader.h>
#import "NSString+StringSanitizer.h"
#import "ODUError.h"
#import <ODManger/ODManager.h>
#import <DHlibxls/DHxlsReader.h>

@implementation ODUFileParser{
    NSMutableArray* rawUserList;
    ODRecordList *internalUserList;
}

//------------------------------------------------
//  DSImport File Creation
//------------------------------------------------

-(void)makeMultiUserFile:(ODUser*)user
              importFile:(NSString*)file
              exportFile:(NSFileHandle*)exportFile
                  filter:(NSString*)filter
               withReply:(void (^)(NSError*error))reply{
    
    NSError* error;
    [self parseUserList:user inFile:file toFile:exportFile filter:filter error:&error];
    reply(error);
}

//------------------------------------------------
//  Multi ODUser Array
//------------------------------------------------

-(void)makeUserArray:(ODUser*)user
          importFile:(NSString*)file
          exportFile:(NSFileHandle*)exportFile
              filter:(NSString*)filter
        andGroupList:(NSArray*)groups
           withReply:(void (^)(NSArray* groupList,ODRecordList* userlist,NSError *error))reply{
    
    NSError* error;
    NSArray* groupList;
    
    if([self parseUserList:user inFile:file toFile:exportFile filter:filter error:&error]){
        groupList = [self makeGroups:groups usingFilter:filter];
    }
    
    reply(groupList,internalUserList,error);
}

-(void)makePasswordResetListFromFile:(NSString *)file
                      usernameColumn:(NSInteger)userNameColumn
                      passwordColumn:(NSInteger)passWordColumn
                               reply:(void (^)(ODRecordList *, NSError *))reply
{
    NSError* error;
    internalUserList = nil;
    DHxlsReader* reader =[DHxlsReader xlsReaderWithPath:file];
    if(!reader){
        error = [ODUError errorWithCode:ODUMReadFileError];
        reply(nil,error);
        return;
    }
    
    [reader startIterator:0];
    int rows = [reader numberOfRowsInSheet:0];
    
    if( rows <= 1 ){
        error = [ODUError errorWithCode:ODUMNoUsersInFile];
        reply(nil,error);
        return;
    }
    
    NSMutableSet* processed = [NSMutableSet set];
    NSMutableArray* returnArray = [NSMutableArray new];
    
    for(int i = 1;i < rows+1;i++ ){
        NSString* userName = [[reader cellInWorkSheetIndex:1 row:i col:userNameColumn] str];
        NSString* passWord = [[reader cellInWorkSheetIndex:1 row:i col:passWordColumn] str];
        
        
        if ([processed containsObject:userName] == NO) {
            [processed addObject:userName];
            @try {
                ODUser* user = [ODUser new];
                user.userName = userName;
                user.passWord = passWord;
                [returnArray addObject:user];
            }
            @catch (NSException *exception) {
                NSLog(@"%@",exception);
            }
        }
    }
    
    if(returnArray){
        internalUserList = [[ODRecordList alloc]init];
        internalUserList.users = [NSArray arrayWithArray:returnArray];
    }
    
    reply(internalUserList,error);
}


-(BOOL)parseUserList:(ODUser*)templateUser inFile:(NSString*)file toFile:(NSFileHandle*)exportFile filter:(NSString*)filter error:(NSError *__autoreleasing*)error{
    NSMutableArray* returnArray = [NSMutableArray new];
    
    if(exportFile){
        [self writeHeaders:exportFile];
    }
    
    DHxlsReader* reader =[DHxlsReader xlsReaderWithPath:file];
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
        
        if([classNumber rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound||
           [filter isEqualToString:@""])
        {
            // the rawUserList is what is used for making groups...
            if(!rawUserList)rawUserList = [[NSMutableArray alloc]init];
            [rawUserList addObject:@{@"name":userName,@"class":classNumber}];
            
            if ([processed containsObject:userName] == NO) {
                [processed addObject:userName];
                @try{
                    
                    ODUser* user = [ODUser new];
                    user.userName = userName;
                    NSString* rawName = [[reader cellInWorkSheetIndex:1 row:i col:2] str];
                    
                    NSArray* rawNameArray = [rawName componentsSeparatedByString:@","];
                    
                    user.passWord = [[reader cellInWorkSheetIndex:1 row:i col:3] str];
                    
                    user.firstName = rawNameArray[1];
                    user.lastName = rawNameArray[0];
                    
                    user.firstName = [[rawNameArray[1] stringByReplacingOccurrencesOfString:@"\"" withString:@""]stringByTrimmingLeadingWhitespace];
                    user.lastName = [[rawNameArray[0] stringByReplacingOccurrencesOfString:@"\"" withString:@""]stringByTrimmingLeadingWhitespace];
                    
                    user.primaryGroup = templateUser.primaryGroup;
                    user.emailDomain = templateUser.emailDomain;
                    user.keyWord = templateUser.keyWord;
                    
                    user.userShell = templateUser.userShell;
                    user.sharePath = templateUser.sharePath;
                    user.sharePoint = templateUser.sharePoint;
                    user.nfsPath = templateUser.nfsPath;
                    
                    /* then write it to the file */
                    if(exportFile)[self writeUser:user toFile:exportFile];
                    [returnArray addObject:user];
                    
                }
                @catch (NSException* exception) {
                }
            }
        }
    }
    
    internalUserList = [ODRecordList new];
    internalUserList.users = [NSArray arrayWithArray:returnArray];
    return YES;
}



-(NSArray*)makeGroups:(NSArray*)groups
          usingFilter:(NSString*)filter{
    
    /* this takes the array of groups/match specified in the main window and then using the users
     from the array set in the parseList method it creates an array of dictionaries of the groups
     and the users that are in them based on the match.  There has to be a better way but this works*/
    
    /* rawUserList is the list created during the parseUserList method
     It is the entire file now as an array of user names */
    if(!rawUserList){
        return nil;
    }
    
    [[NSApp delegate] setProgressMsg:@"Determining Group Membership..."];
    
    NSMutableSet* groupProcessed = [[NSMutableSet alloc]init];
    NSMutableArray* returnArray = [[NSMutableArray alloc]init];
    
    NSMutableSet* userSet;
    
    NSString* groupName;
    BOOL isSameGroup = NO;
    
    
    for(NSDictionary* g in groups){
        if (![groupName isEqualToString:g[@"group"]]){
            groupName = g[@"group"];
            isSameGroup = NO;
        }else{
            isSameGroup = YES;
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"class contains[c] %@",g[@"match"]];
        
        if (![groupProcessed containsObject:groupName]){
            userSet = [NSMutableSet new];
            [groupProcessed addObject:groupName];
        }
        
        for(NSDictionary *u in rawUserList){
            if ([predicate evaluateWithObject:u]){
                [userSet addObject:u[@"name"]];
            }
        }
        
        if(isSameGroup)[returnArray removeLastObject];
        if(userSet.count){
            [returnArray addObject:@{@"users":[userSet allObjects],@"group":groupName}];
        }
    }
    
    return [NSArray arrayWithArray:returnArray];
}


//------------------------------------------------
//  Common Items
//------------------------------------------------


-(BOOL)writeUser:(ODUser*)user toFile:(NSFileHandle*)fh{
    /* Set up the actual elements we'll need */
    NSString* homeDir = user.homeDirectory ? user.homeDirectory:@"";
    NSString* userName = user.userName;
    NSString* fullName = [NSString stringWithFormat:@"%@ %@",user.firstName, user.lastName];
    NSString* firstName = user.firstName;
    NSString* lastName = user.lastName;
    NSString* email = [NSString stringWithFormat:@"%@@%@",user.userName,user.emailDomain];
    NSString* uuid;
    
    if(user.uid){
        uuid = user.uid;
    }else{
        uuid = [userName uuidWithLength:6];
    }
    
    NSString* password = user.passWord;
    NSString* passwordPolicy = [self setPasswordPoilcy];
    NSString* primaryGroup = user.primaryGroup;
    NSString* nfsHome = [user.nfsPath stringByAppendingPathComponent:user.userName];
    NSString* keyWords = user.keyWord ? user.keyWord:@"";
    
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


@end
