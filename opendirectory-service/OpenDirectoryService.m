//
//  OpenDirectoryService.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/21/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "OpenDirectoryService.h"
#import "TBXML.h"
#import "NSString+uuidFromString.h"

@implementation OpenDirectoryService

-(void)addSingleUser:(User*)user toServer:(Server*)server andGroups:(NSArray*)groups withReply:(void (^)(NSError *error))reply{
    NSError* error = nil;
    ODNode *node;
    ODRecord* userRecord;
    ODRecord* userPreset;
    NSString* progress;
    
    [self getAuthenticatedNode:&node forServer:server withError:&error];
    
    if(error){
        goto nsxpc_return;
    }
    
    userRecord = [self getUserRecord:user.userName withNode:node];
    if(userRecord){
        SET_ERROR(1, ODUMUserAlreadyExistsMsg);
        goto update_group;
    }
    
    userPreset = [self getPresetRecord:user.userPreset ForNode:node];
    
    if(!userPreset){
        SET_ERROR(1, ODUMUserNotFoundMsg);
        goto nsxpc_return;
    }else{
        // get the afp home directory record and parse it out
        NSString *afph = [[userPreset valuesForAttribute:kODAttributeTypeHomeDirectory error:nil]objectAtIndex:0];
        NSData *data = [afph dataUsingEncoding:NSUTF8StringEncoding];
        
        TBXML *xml = [[TBXML alloc]initWithXMLData:data error:nil];
        TBXMLElement *rootElement = [xml rootXMLElement];
        TBXMLElement *path = [TBXML childElementNamed:@"path" parentElement:rootElement];
        TBXMLElement *url = [TBXML childElementNamed:@"url" parentElement:rootElement];
        
        user.afpURL = [NSString stringWithUTF8String:url->text];
        user.afpPath = [NSString stringWithUTF8String:path->text];
        
        // get set nfsHome attr
        user.nfsPath = [[userPreset valuesForAttribute:kODAttributeTypeNFSHomeDirectory error:nil]objectAtIndex:0];
        user.userShell = [[userPreset valuesForAttribute:kODAttributeTypeUserShell error:nil]objectAtIndex:0];
    }
    
    userRecord = [self createNewUser:user withNode:node error:&error];

    if(!userRecord){
        goto nsxpc_return;
    }
    
update_group:
    for(NSString *g in groups){
        error = nil;
        progress = [NSString stringWithFormat:@"Adding %@ to group %@...",user.userName,g];
        [[self.xpcConnection remoteObjectProxy] setProgressMsg:progress];

        ODRecord* groupRecord = [self getGroupRecord:g withNode:node];
        [groupRecord addMemberRecord:userRecord error:&error];
        if(error){
            SET_ERROR(1, ODUMCantAddUserToGroupMSG);
        }
    }
 
    
nsxpc_return:
    reply(error);
}



-(void)resetUserPassword:(User*)user onServer:(Server*)server withReply:(void (^)(NSError *error))reply{
    NSError *error = nil;
    ODNode *node;
    ODRecord* userRecord;
    
    [self getAuthenticatedNode:&node forServer:server withError:&error];
    if(error){
        goto nsxpc_return;
    }
    
    userRecord = [self getUserRecord:user.userName withNode:node];
    
    if(userRecord){
        [userRecord changePassword:nil toPassword:user.userCWID error:&error];
        [userRecord synchronizeAndReturnError:&error];
    }else{
        SET_ERROR(1, ODUMUserNotFoundMsg);
    }
nsxpc_return:
    reply(error);
}

//--------------------------------------------------------------
//
//--------------------------------------------------------------

-(ODRecord*)createNewUser:(User*)user withNode:(ODNode*)node error:(NSError**)error{
    
    NSMutableDictionary *settings = [[NSMutableDictionary alloc]init];
    
    if(user.afpPath && user.afpURL){
        NSString* afpHome = [NSString stringWithFormat:@"<home_dir><url>%@</url><path>%@%@</path></home_dir>",user.afpURL,user.afpPath,user.userName];
        [settings setObject:[NSArray arrayWithObject:afpHome] forKey:kODAttributeTypeHomeDirectory];
    }
    
    if(user.nfsPath){
        NSString* nfsHome = [NSString stringWithFormat:@"%@%@",user.nfsPath,user.userName];
        [settings setObject:[NSArray arrayWithObject:nfsHome] forKey:kODAttributeTypeNFSHomeDirectory];
    }
    
    if(!user.userUUID){
        user.userUUID = [user.userName uuidFromString];
    }
    
    if(!user.userShell){
        user.userShell = @"/dev/null";
        [settings setObject:[NSArray arrayWithObject:user.userShell] forKey:kODAttributeTypeUserShell];
        
    }
    
    [settings setObject:[NSArray arrayWithObject:user.primaryGroup] forKey:kODAttributeTypePrimaryGroupID];
    [settings setObject:[NSArray arrayWithObject:user.firstName] forKey:kODAttributeTypeFirstName];
    [settings setObject:[NSArray arrayWithObject:user.lastName] forKey:kODAttributeTypeLastName];
    [settings setObject:[NSArray arrayWithObject:user.userUUID] forKey:kODAttributeTypeUniqueID];
    [settings setObject:[NSArray arrayWithObject:[NSString stringWithFormat:@"%@ %@",user.firstName,user.lastName]] forKey:kODAttributeTypeFullName];
    
    ODRecord* userRecord = [node createRecordWithRecordType:kODRecordTypeUsers name:user.userName attributes:settings error:&*error];
    [userRecord changePassword:nil toPassword:user.userCWID error:&*error];
    
    return userRecord;
}



-(void)addGroups:(NSArray*)groups toServer:(Server*)server withReply:(void (^)(NSError *))reply{
    NSError *error = nil;
    ODNode *node;
    
    [self getAuthenticatedNode:&node forServer:server withError:&error];
    
    if(error){
        goto nsxpc_return;
    }

    for(NSDictionary* g in groups){
        NSString* groupName = [ g objectForKey:@"group"];
        NSArray* userNames = [ g objectForKey:@"users"];
        ODRecord* groupRecord = [self getGroupRecord:groupName withNode:node];
        
        for(NSString* u in userNames){
            [[self.xpcConnection remoteObjectProxy] setProgressMsg:[NSString stringWithFormat:@"Updating %@ membership, adding %@",groupName,u]];
            
            //NSLog(@"adding %@ to %@",u,groupName);
            ODRecord* userRecord = [self getUserRecord:u withNode:node];
            
            if(userRecord){
                NSError* err;
                [groupRecord addMemberRecord:userRecord error:&err];
                if(err)
                    NSLog(@"Error:%@",[err localizedDescription]);
            }
        }
    }
nsxpc_return:
    reply(error);
}


-(void)addUser:(User *)user toGroup:(NSArray *)group toServer:(Server *)server withReply:(void (^)(NSError *error))reply{
    NSError *error = nil;
    ODNode *node;
    ODRecord* userRecord;
    
    [self getAuthenticatedNode:&node forServer:server withError:&error];
    
    if(error){
        goto nsxpc_return;
    }

    userRecord = [self getUserRecord:user.userName withNode:node];

    for(NSString* g in group){
        ODRecord* groupRecord = [self getGroupRecord:g withNode:node];
        [groupRecord addMemberRecord:userRecord error:&error];
    }
nsxpc_return:
    reply(error);
}



-(void)getUserPresets:(Server*)server withReply:(void (^)(NSArray *userPreset,NSError *error))reply{
    NSError *error = nil;
    ODNode *node;
    ODRecord *record;
    NSArray *odArray;
    NSMutableArray *userPresets;
    ODQuery *query;

    [self getNode:&node forServer:server withError:&error];

    if(!node){
        goto nsxpc_return;        
    }

    
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
        NSError *err;
        NSArray *recordName = [record valuesForAttribute:kODAttributeTypeRecordName error:&err];
        
        if ([recordName count]) {
            [userPresets addObject:[recordName objectAtIndex:0]];
        }
    }
nsxpc_return:
    reply(userPresets,error);
}


-(void)getGroupListFromServer:(Server*)server withReply:(void (^)(NSArray *groupList,NSError *error))reply{
    NSError *error = nil;
    ODNode *node;
    NSArray * odArray;
    ODQuery *query;
    NSMutableArray *groupList;
    ODRecord *record;

    
    [self getNode:&node forServer:server withError:&error];
    if(!node){
        goto nsxpc_return;        
    }
    
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

-(void)getUserListFromServer:(Server*)server withReply:(void (^)(NSArray *userList,NSError *error))reply{
    NSError *error = nil;
    ODNode *node;
    ODRecord *record;
    ODQuery *query;
    NSArray *odArray;
    NSMutableArray *userList;
    
    [self getNode:&node forServer:server withError:&error];
    
    if(!node){
        goto nsxpc_return;        
    }
    
    query = [ODQuery  queryWithNode: node
                              forRecordTypes: kODRecordTypeUsers
                                   attribute: kODAttributeTypeAllAttributes
                                   matchType: kODMatchAny
                                 queryValues: nil
                            returnAttributes: kODAttributeTypeStandardOnly
                              maximumResults: 0
                                       error: &error];
    
    
    odArray = [query resultsAllowingPartial:NO error:&error];
    userList = [NSMutableArray arrayWithCapacity:[odArray count]];
    
    for (record in odArray) {
        NSError *err;
        NSArray *recordName = [record valuesForAttribute:kODAttributeTypeRecordName error:&err];
        
        if ([recordName count]) {
            [userList addObject:[recordName objectAtIndex:0]];
        }
    }
    
nsxpc_return:
    reply(userList,error);
}

-(void)checkCredentials:(Server*)server withReply:(void (^)(BOOL authenticated))reply{
    BOOL authenticated = NO;
    NSError *error = nil;
    ODNode *node;
    
    [self getNode:&node forServer:server withError:&error];
    
    if(!node){
        goto nsxpc_return;        
    }
    
    authenticated = [node setCredentialsWithRecordType:nil recordName:server.diradminName password:server.diradminPass error:nil];
    
nsxpc_return:
    reply(authenticated);
}

//---------------------------------------------
//  Record Retrevial methods
//---------------------------------------------

-(ODRecord*)getGroupRecord:(NSString*)group withNode:(ODNode*)node{
    ODRecord* record;
    ODQuery *query = [ODQuery  queryWithNode: node
                              forRecordTypes: kODRecordTypeGroups
                                   attribute: kODAttributeTypeRecordName
                                   matchType: kODMatchEqualTo
                                 queryValues: group
                            returnAttributes: kODAttributeTypeStandardOnly
                              maximumResults: 1
                                       error: nil];
    
    NSArray * odArray = [query resultsAllowingPartial:NO error:nil];
    
    record = [odArray objectAtIndex:0];
    
    return record;
    
}

-(ODRecord*)getPresetRecord:(NSString*)preset
                         ForNode:(ODNode*)node{
    ODQuery *upQuery = [ODQuery  queryWithNode: node
                                forRecordTypes: kODRecordTypePresetUsers
                                     attribute: kODAttributeTypeRecordName
                                     matchType: kODMatchEqualTo
                                   queryValues: preset
                              returnAttributes: kODAttributeTypeStandardOnly
                                maximumResults: 1
                                         error: nil];
    
    NSArray *odArray = [[NSArray alloc]init];
    odArray = [upQuery resultsAllowingPartial:NO error:nil];
    ODRecord* record = [odArray objectAtIndex:0];
    
    return record;
}

-(ODRecord*)getUserRecord:(NSString*)user withNode:(ODNode*)node{
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
    
    if(odArray.count > 0){
        record = [odArray objectAtIndex:0];
    }
    
    return record;
}

-(void)getAuthenticatedNode:(ODNode**)node forServer:(Server*)server withError:(NSError**)error{    
    /* first try to get node if this computer is bound to directory
        if it's not then connect via a proxy */
    *node = [self getLocalServerNode:server.serverName];
    
    if(!node){
        *node = [self getRemServerNode:server];
    }
    if(!node){
        *error = [ODUserError errorWithCode:1 message:ODUMCantConnectToNodeMsg];
    }
    
    [*node setCredentialsWithRecordType:nil recordName:server.diradminName password:server.diradminPass error:&*error];
    if(*error){
        *error = [ODUserError errorWithCode:1 message:ODUMCantAuthenicateMsg];
    }
}

-(void)getNode:(ODNode**)node forServer:(Server*)server withError:(NSError**)error{
    *node = [self getLocalServerNode:server.serverName];
    
    if(!node){
        *node = [self getRemServerNode:server];
    }
    
    if(!node){
        *error = [ODUserError errorWithCode:1 message:ODUMCantConnectToNodeMsg];
    }
}


-(ODNode*)getLocalServerNode:(NSString*) serverName{
    ODSession *session = [ODSession defaultSession];
    
    NSError *error;
    NSString *ldap = [NSString stringWithFormat:@"/LDAPv3/%@",serverName];
    ODNode *node = [ODNode nodeWithSession:session name:ldap error:&error];
        
    if(!node){
        return nil;
    }
    return node;
}


-(ODNode*)getRemServerNode:(Server*)server{
    
    NSError* error = nil;
    NSDictionary* settings = [NSDictionary dictionaryWithObjectsAndKeys:server.serverName,ODSessionProxyAddress,@"0",ODSessionProxyPort,server.diradminName,ODSessionProxyUsername,server.diradminPass,ODSessionProxyPassword, nil];
    
    ODSession *session = [ODSession sessionWithOptions:settings error:&error];
    
    if(error){
        NSLog(@"%@",[error localizedDescription]);
        return nil;
    }
    
    NSString *ldap = [NSString stringWithFormat:@"/LDAPv3/127.0.0.1"];
    ODNode *node = [ODNode nodeWithSession:session name:ldap error:&error];
    
    if(!node){
        return nil;
    }
    return node;
}

//---------------------------------------------
//  Open Directory Node Status Checks
//---------------------------------------------


-(void)checkServerStatus:(NSString*)server withReply:(void (^)(BOOL connected))reply{
    BOOL connected = YES;
    if(![self getLocalServerNode:server])
        connected = NO;
    reply(connected);
}



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


@end
