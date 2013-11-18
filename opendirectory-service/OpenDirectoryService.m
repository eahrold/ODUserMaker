//
//  OpenDirectoryService.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/21/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "OpenDirectoryService.h"
#import "ODCommonHeaders.h"

#import "TBXML.h"
#import "NSString+uuidFromString.h"
#import <syslog.h>

@implementation OpenDirectoryService{
    ODNode* node;
    BOOL ImportStatus;
}
//------------------------------------------------------------
//  NSXPC methods for App Controller
//------------------------------------------------------------


-(void)addSingleUser:(User*)user andGroups:(NSArray*)groups withReply:(void (^)(NSError *error))reply{
    NSError* error = nil;
    BOOL userError = NO;
    BOOL groupError = NO;

    ODRecord* userRecord;
    NSString* progress;
    
    userRecord = [self getUserRecord:user.userName];
    if(userRecord){
        error = [ODUserError errorWithCode:ODUMUserAlreadyExists];
        userError = YES;
        goto update_group;
    }
    
    userRecord = [self createNewUser:user error:&error];

    if(!userRecord){
        goto nsxpc_return;
    }
    
update_group:
    for(NSString *g in groups){
        progress = [NSString stringWithFormat:@"Adding %@ to group %@...",user.userName,g];
        [[self.xpcConnection remoteObjectProxy] setProgressMsg:progress];

        ODRecord* groupRecord = [self getGroupRecord:g];
        if(groupRecord){
            [groupRecord addMemberRecord:userRecord error:nil];
        }else{
            groupError = YES;
        }
    }
 
    if(userError && groupError){
        error = [ODUserError errorWithCode:ODUMCantAddUserToServerOrGroup ];
    }else if (groupError){
        error = [ODUserError errorWithCode:ODUMCantAddUserToGroup ];
    }
    
nsxpc_return:
    reply(error);
}


-(void)addListOfUsers:(User*)user withReply:(void (^)(NSError *error))reply{
    replyBlock = reply;
    
    // in 10.8 you could run what you needed to right here,
    // as of 10.9 to recieve status updates in the main app
    // this needs to be in the background.
    [self performSelectorInBackground:@selector(userListAdd:) withObject:user];
    
}

-(void)userListAdd:(User*)user{
    NSError* error = nil;
    ImportStatus = TRUE;
    
    // We want to log these issues, so we'll get a collection and log once
    // so as to keep NSLog from spinning out of control
    NSMutableSet* notAdded = [NSMutableSet new];
    NSMutableSet* wereAdded = [NSMutableSet new];
    NSMutableSet* problemAdding = [NSMutableSet new];
    
    NSInteger count = [user.userList count];
    NSInteger pgcount = 1;
    NSString* progressMessage;
    
    double progress = 100.0/count;
    
    while (ImportStatus) {
        for(NSDictionary* dict in user.userList){
            error = nil;
            
            if(!ImportStatus)break;
            
            user.userName  = dict[@"userName"];
            user.firstName = dict[@"firstName"];
            user.lastName  = dict[@"lastName"];
            user.userCWID  = dict[@"userCWID"];
            user.userUUID  = nil; // <-- nil this out since the UUID's not used when importing a list of uses...
            
            progressMessage = [NSString stringWithFormat:@"Adding %ld/%ld: %@...",(long)pgcount,(long)count,user.userName];
            
            [[self.xpcConnection remoteObjectProxy]setProgress:progress withMessage:progressMessage];
            
            ODRecord* userRecord = [self getUserRecord:user.userName];
            if(userRecord){
                [notAdded addObject:user.userName];
            }else{
                [self createNewUser:user error:&error];
                if(error){
                    [problemAdding addObject:user.userName];
                }else{
                    [wereAdded addObject:user.userName];
                }
            }
            pgcount++;
        }
        break;
    }
    
    if([notAdded count] > 0){
        NSLog(@"These users already existed on the server and were skipped: %@",notAdded);
    }
    if([wereAdded count] > 0){
        NSLog(@"We added %lu users to the Directory: %@",(unsigned long)wereAdded.count,wereAdded);
    }
    if([problemAdding count] > 0){
        NSLog(@"There was a problem adding these users to Directory: %@",problemAdding);
    }
    
    if(user.groupList.count > 0){
        error = nil;
        [self addGroups:user.groupList error:&error];
    }
    
    ImportStatus = NO;
    
    replyBlock(error);

}
-(void)updateProgress:(NSString*)progress{
    [[self.xpcConnection remoteObjectProxy]setProgressMsg:progress];
}

-(void)cancelImportStatus:(void (^)(OSStatus connected))reply{
    ImportStatus = FALSE;
    reply(YES);
}

-(void)resetUserPassword:(User*)user withReply:(void (^)(NSError *error))reply{
    NSError *error = nil;
    ODRecord* userRecord;

    userRecord = [self getUserRecord:user.userName];
    
    if(userRecord){
        [userRecord changePassword:nil toPassword:user.userCWID error:&error];
        [userRecord synchronizeAndReturnError:&error];
    }else{
        error = [ODUserError errorWithCode:ODUMUserNotFound];
    }
    
    reply(error);
}

//--------------------------------------------------------------
//  Private Methods for Editing Users and Groups
//--------------------------------------------------------------

-(ODRecord*)createNewUser:(User*)user error:(NSError**)error{
    NSError* localError = nil;
    
    NSMutableDictionary *settings = [[NSMutableDictionary alloc]init];
    
    if(user.sharePoint){
        if(!user.sharePath){
            user.sharePath = @"";
        }
        
        NSString* homeDirectory = [NSString stringWithFormat:@"<home_dir><url>%@</url><path>%@%@</path></home_dir>",user.sharePoint,user.sharePath,user.userName];
        [settings setObject:[NSArray arrayWithObject:homeDirectory] forKey:kODAttributeTypeHomeDirectory];
    }
    
    if(user.nfsPath){
        NSString* nfsHome = [NSString stringWithFormat:@"%@%@",user.nfsPath,user.userName];
        [settings setObject:[NSArray arrayWithObject:nfsHome] forKey:kODAttributeTypeNFSHomeDirectory];
    }
    
    if(user.emailDomain){
        NSString* emailAddress = [NSString stringWithFormat:@"%@@%@",user.userName,user.emailDomain];
        [settings setObject:[NSArray arrayWithObject:emailAddress] forKey:kODAttributeTypeEMailAddress];
    }
    
    if(!user.userUUID){
        user.userUUID = [user.userName uuidFromString];
    }
    
    if(!user.userShell){
        user.userShell = @"/dev/null";
    }

    [settings setObject:[NSArray arrayWithObject:user.primaryGroup] forKey:kODAttributeTypePrimaryGroupID];
    [settings setObject:[NSArray arrayWithObject:user.firstName] forKey:kODAttributeTypeFirstName];
    [settings setObject:[NSArray arrayWithObject:user.lastName] forKey:kODAttributeTypeLastName];
    [settings setObject:[NSArray arrayWithObject:user.userUUID] forKey:kODAttributeTypeUniqueID];
    [settings setObject:[NSArray arrayWithObject:[NSString stringWithFormat:@"%@ %@",user.firstName,user.lastName]] forKey:kODAttributeTypeFullName];
    [settings setObject:[NSArray arrayWithObject:user.userShell] forKey:kODAttributeTypeUserShell];
    
    ODRecord* userRecord = [node createRecordWithRecordType:kODRecordTypeUsers name:user.userName attributes:settings error:&localError];
    [userRecord changePassword:nil toPassword:user.userCWID error:&localError];
    
    if (error) *error = localError;
    return userRecord;
}


-(BOOL)addGroups:(NSArray*)groups error:(NSError**)error{
    BOOL rc = YES;
    NSError* localError =nil;
    ODRecord* userRecord;
    ODRecord* groupRecord;
    NSArray* userNames;
    NSString* groupName;
    
    for(NSDictionary* g in groups){
        groupName = [ g objectForKey:@"group"];
        userNames = [ g objectForKey:@"users"];
        groupRecord = [self getGroupRecord:groupName];
        
        for(NSString* u in userNames){
            [[self.xpcConnection remoteObjectProxy] setProgressMsg:[NSString stringWithFormat:@"Updating %@ membership, adding %@",groupName,u]];
            
            userRecord = [self getUserRecord:u];
            
            if(userRecord){
                [groupRecord addMemberRecord:userRecord error:&localError];
                if(localError){
                    NSLog(@"Couldn't add %@ to %@: %@",u,g,[localError localizedDescription]);
                    localError = nil;
                }
            }
        }
    }

    return rc;
}

#pragma mark -- NSXPC Listener methods
//------------------------------------------------------------
//  NSXPC methods
//------------------------------------------------------------

-(void)getUserPresets:(void (^)(NSArray *userPreset,NSError *error))reply{
    NSError *error = nil;
    ODRecord *record;
    NSArray *odArray;
    NSMutableArray *userPresets;
    ODQuery *query;
  
    query = [ODQuery  queryWithNode: node
                                forRecordTypes: kODRecordTypePresetUsers
                                     attribute: kODAttributeTypeRecordName
                                     matchType: kODMatchAny
                                   queryValues: nil
                              returnAttributes: kODAttributeTypeStandardOnly
                                maximumResults: 0
                                         error: &error];
    
    odArray = [query resultsAllowingPartial:NO error:&error];
    userPresets = [NSMutableArray arrayWithCapacity:[odArray count]];
    
    for (record in odArray) {
        NSMutableDictionary* dict = [NSMutableDictionary new];
        NSError *err;
        NSArray *arr;
        
        arr = [record valuesForAttribute:kODAttributeTypeRecordName error:&err];
        if ([arr count]) {
            [dict setObject:[arr objectAtIndex:0] forKey:@"presetName"];
        }
        
        arr = [record valuesForAttribute:kODAttributeTypeNFSHomeDirectory error:nil];
        if([arr count]){
            [dict setObject:[arr objectAtIndex:0] forKey:@"NFSHome"];
        }
        
        arr = [record valuesForAttribute:kODAttributeTypeUserShell error:nil];
        if([arr count]){
            [dict setObject:[arr objectAtIndex:0]forKey:@"userShell"];
        }

        arr = [record valuesForAttribute:kODAttributeTypeHomeDirectory error:nil];
        if([arr count]){
            NSString* url = [self getValueForKey:@"url" fromXMLString:[arr objectAtIndex:0]];
            NSString* path = [self getValueForKey:@"path" fromXMLString:[arr objectAtIndex:0]];
            [dict setObject:path forKey:@"sharePath"];
            [dict setObject:url forKey:@"sharePoint"];
        }
        [userPresets addObject:dict];
    }
nsxpc_return:
    reply(userPresets,error);
}

-(void)getSettingsForPreset:(NSString*)preset
                  withReply:(void (^)(NSDictionary *settings,NSError *error))reply{
    
    NSMutableDictionary* dict = [NSMutableDictionary new];
    NSDictionary *settings;
    NSError* error = nil;
    NSArray *odArray;
    ODRecord *record;
    ODQuery * query;

    NSString* shareFull;
    NSString* sharePoint;
    NSString* sharePath;
    NSString* NFSHome;
    NSString* userShell;
    NSArray* arr;
    
   
    
    
    query = [ODQuery  queryWithNode: node
                     forRecordTypes: kODRecordTypePresetUsers
                          attribute: kODAttributeTypeRecordName
                          matchType: kODMatchEqualTo
                        queryValues: preset
                   returnAttributes: kODAttributeTypeStandardOnly
                     maximumResults: 0
                              error: &error];
    
    odArray = [query resultsAllowingPartial:NO error:&error];
    if([odArray count]){
        record = [odArray objectAtIndex:0];
    }
    
    arr = [record valuesForAttribute:kODAttributeTypeHomeDirectory error:nil];
    if([arr count]){
        shareFull = [arr objectAtIndex:0];
    }
    
    arr = [record valuesForAttribute:kODAttributeTypeNFSHomeDirectory error:nil];
    if([arr count]){
        NFSHome = [arr objectAtIndex:0];
    }
    
    arr = [record valuesForAttribute:kODAttributeTypeUserShell error:nil];
    if([arr count]){
        userShell = [arr objectAtIndex:0];
    }
    
    
    sharePoint = [self getValueForKey:@"url" fromXMLString:shareFull];
    sharePath = [self getValueForKey:@"path" fromXMLString:shareFull];
    
    [dict setObject:sharePoint forKey:@"sharePoint"];
    [dict setObject:sharePath forKey:@"sharePath"];
    [dict setObject:NFSHome forKey:@"NFSHome"];
    [dict setObject:userShell forKey:@"userShell"];
    
    
nsxpc_return:
    settings = [NSDictionary dictionaryWithDictionary:dict];
    reply(settings,error);
}

-(void)getGroupListFromServer:(void (^)(NSArray *groupList,NSError *error))reply{
    NSError *error = nil;
    NSArray * odArray;
    ODQuery *query;
    NSMutableArray *groupList;
    ODRecord *record;
    
    query = [ODQuery  queryWithNode: node
                              forRecordTypes: kODRecordTypeGroups
                                   attribute: kODAttributeTypeRecordName
                                   matchType: kODMatchAny
                                 queryValues: nil
                            returnAttributes: kODAttributeTypeStandardOnly
                              maximumResults: 0
                                       error: &error];
    
    odArray = [query resultsAllowingPartial:NO error:&error];
    
    groupList = [NSMutableArray arrayWithCapacity:[odArray count]];
    
    for (record in odArray) {
        NSError *err;
        NSArray *recordName = [record valuesForAttribute:kODAttributeTypeRecordName error:&err];
        
        if ([recordName count]) {
            [groupList addObject:[recordName objectAtIndex:0]];
        }
    }
    
nsxpc_return:
    reply(groupList,error);
}

-(void)getUserListFromServer:(void (^)(NSArray *userList,NSError *error))reply{
    NSError *error = nil;
    ODRecord *record;
    ODQuery *query;
    NSArray *odArray;
    NSMutableArray *userList;
    
    query = [ODQuery  queryWithNode: node
                        forRecordTypes: kODRecordTypeUsers
                                   attribute: kODAttributeTypeAllAttributes
                                   matchType: kODMatchAny
                                 queryValues: nil
                            returnAttributes: kODAttributeTypeStandardOnly
                              maximumResults: 0
                                       error: &error];
    
    if(error){
        reply(nil,error);
        return;
    }
    
//    DSReplyBlock = reply;
//    [query setDelegate:self];
//    [query scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    odArray = [query resultsAllowingPartial:NO error:&error];
    userList = [NSMutableArray arrayWithCapacity:[odArray count]];
    
    for (record in odArray) {
        NSError *err;
        NSArray *recordName = [record valuesForAttribute:kODAttributeTypeRecordName error:&err];
        
        if ([recordName count]) {
            [userList addObject:[recordName objectAtIndex:0]];
        }
    }
    
   reply(userList,error);
}


//---------------------------------------------
//  Record Retrevial methods
//---------------------------------------------

-(ODRecord*)getGroupRecord:(NSString*)group{
    ODRecord* record = nil;
    ODQuery *query = [ODQuery  queryWithNode: node
                              forRecordTypes: kODRecordTypeGroups
                                   attribute: kODAttributeTypeRecordName
                                   matchType: kODMatchEqualTo
                                 queryValues: group
                            returnAttributes: kODAttributeTypeStandardOnly
                              maximumResults: 1
                                       error: nil];
    
    NSArray * odArray = [query resultsAllowingPartial:NO error:nil];
    
    if([odArray count]){
        record = [odArray objectAtIndex:0];
    }
    
    return record;
    
}

-(ODRecord*)getPresetRecord:(NSString*)preset{
    ODRecord* record = nil;
    ODQuery *upQuery = [ODQuery  queryWithNode: node
                                forRecordTypes: kODRecordTypePresetUsers
                                     attribute: kODAttributeTypeRecordName
                                     matchType: kODMatchEqualTo
                                   queryValues: preset
                              returnAttributes: kODAttributeTypeStandardOnly
                                maximumResults: 1
                                         error: nil];
    
    NSArray *odArray = [upQuery resultsAllowingPartial:NO error:nil];
    
    if([odArray count]){
        record = [odArray objectAtIndex:0];
    }
    
    return record;
}

-(ODRecord*)getUserRecord:(NSString*)user{
    ODRecord* record = nil;
    ODQuery *query = [ODQuery  queryWithNode: node
                              forRecordTypes: kODRecordTypeUsers
                                   attribute: kODAttributeTypeRecordName
                                   matchType: kODMatchEqualTo
                                 queryValues: user
                            returnAttributes: kODAttributeTypeStandardOnly
                              maximumResults: 1
                                       error: nil];
    
    NSArray *odArray = [query resultsAllowingPartial:NO error:nil];
    
    if([odArray count]){
        record = [odArray objectAtIndex:0];
    }
    
    return record;
}


-(BOOL)getLocalServerNode:(NSString*)serverName error:(NSError**)error{
    NSError* localError = nil;
    
    ODSession *session = [ODSession defaultSession];
    NSString *ldap = [NSString stringWithFormat:@"/LDAPv3/%@",serverName];
    node = [ODNode nodeWithSession:session name:ldap error:&localError];
    if(!node){
        if (error)*error = localError;
        return NO;
    }
    
    return YES;
}


-(BOOL)getRemServerNode:(Server*)server error:(NSError**)error{
    NSError* localError = nil;
    
    if(!server.serverName || !server.diradminName || !server.diradminPass){
        NSLog(@"We were lacking some bit of information need for the proxy connection");
        return NO;
    }
    
    NSDictionary* settings = [NSDictionary dictionaryWithObjectsAndKeys:server.serverName,ODSessionProxyAddress,@"0",ODSessionProxyPort,server.diradminName,ODSessionProxyUsername,server.diradminPass,ODSessionProxyPassword, nil];
    
    ODSession *session = [ODSession sessionWithOptions:settings error:&localError];
    
    if(localError){
        NSLog(@"%@",[localError localizedDescription]);
        if (error) *error = localError;
        return NO;
    }
    
    NSString *ldap = [NSString stringWithFormat:@"/LDAPv3/127.0.0.1"];
    node = [ODNode nodeWithSession:session name:ldap error:&localError];
    
    if(localError){
        NSLog(@"%@",[localError localizedDescription]);
        if (error) *error = localError;
        return NO;
    }
    return YES;
}


//---------------------------------------------
//  Open Directory Node Status Checks
//---------------------------------------------


-(void)checkServerStatus:(Server*)server withReply:(void (^)(OSStatus connected))reply{
    // init the query set here since whenever we change the server,the old querys will no longer be accessible
 
    OSStatus status = ODUNoNode;
    NSError* nodeError = nil;
    NSError* authError = nil;
    
    if([self getLocalServerNode:server.serverName error:&nodeError]){
        [node setCredentialsWithRecordType:nil recordName:server.diradminName password:server.diradminPass error:&authError];
        if(!authError){
            status = ODUAuthenticatedLocal;
        }else{
            status = ODUUnauthenticatedLocal;
            NSLog(@"Local Node error: %@",authError.localizedDescription);
        }
        
    }else if([self getRemServerNode:server error:&nodeError]){
        [node setCredentialsWithRecordType:nil recordName:server.diradminName password:server.diradminPass error:&authError];
        if(!authError){
            status = ODUAuthenticatedProxy;
        }else{
            NSLog(@"Proxy Node Error: %@",authError.localizedDescription);
            status = ODUUnauthenticatedProxy;
        }
    }else{
        status = ODUUnauthenticatedProxy;
    }
    reply(status);
}

//---------------------------------------------
//  Open Directory Delegate Methods
//---------------------------------------------
- (void)query:(ODQuery *)inSearch foundResults:(NSArray *)inResults error:(NSError *)inError
{
    NSMutableArray* array = [[NSMutableArray alloc]init];
    NSLog(@"Query Delgate Method Started");
    if (!inResults && !inError) {
        [inSearch removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        DSReplyBlock(array,inError);
    }
    
    for (ODRecord *record in inResults) {
        NSArray *recordName = [record valuesForAttribute:kODAttributeTypeRecordName error:nil];
        
        if ([recordName count]) {
            NSString* rn = recordName[0];
            //[[self.xpcConnection remoteObjectProxy] updateUserListArrayWithString:rn];
            //[array addObject:recordName[0]];
        }
    }
}


#pragma mark -- singleton
//---------------------------------
//  Singleton and ListenerDelegate
//---------------------------------

+ (OpenDirectoryService*)sharedDirectoryServer {
    static dispatch_once_t onceToken;
    static OpenDirectoryService* shared;
    dispatch_once(&onceToken, ^{
        shared = [OpenDirectoryService new];
    });
    return shared;
}


/* Implement the one method in the NSXPCListenerDelegate protocol.*/
- (BOOL)listener:(NSXPCListener*)listener shouldAcceptNewConnection:(NSXPCConnection*)newConnection {
    
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    newConnection.exportedObject = self;
    
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    self.xpcConnection = newConnection;
    
    [newConnection resume];
    
    return YES;
}


//---------------------------------------------
//  Utility Methods
//---------------------------------------------

-(NSString*)getValueForKey:(NSString*)key fromXMLString:(NSString*)xml{
    NSString* reply = nil;
    NSData *data = [xml dataUsingEncoding:NSUTF8StringEncoding];
    
    if(data){
        TBXML *xml = [[TBXML alloc]initWithXMLData:data error:nil];
        TBXMLElement *rootElement = [xml rootXMLElement];
        TBXMLElement *tableVal = [TBXML childElementNamed:key parentElement:rootElement];
        reply = [NSString stringWithUTF8String:tableVal->text];
    }
    return reply;
}



@end
