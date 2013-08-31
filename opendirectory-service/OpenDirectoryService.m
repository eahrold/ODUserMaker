//
//  OpenDirectoryService.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/21/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "OpenDirectoryService.h"


@implementation OpenDirectoryService

-(void)resetUserPassword:(User*)user onServer:(Server*)server withReply:(void (^)(NSError *error))reply{
    NSError *error = nil;
    ODNode *node;
    ODRecord* userRecord;
    
    /* see if computer is connected to the directory server, if not get a proxy node. */
    if([self checkServerStatus:server.serverName]){
        node = [self getServerNode:server.serverName];
    }else{
        node = [self getRemServerNode:server];
    }
    
    if(!node){
        SET_ERROR(1, ODUMCantConnectToNodeMsg);
        goto nsxpc_return;
    }
    
    [node setCredentialsWithRecordType:nil recordName:server.diradminName password:server.diradminPass error:&error];
    
    if(error){
        SET_ERROR(1, ODUMCantAuthenicateMsg);
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

-(void)addGroups:(NSArray*)groups toServer:(Server*)server withReply:(void (^)(NSError *))reply{
    NSError *error = nil;
    ODNode *node;
    
    /* see if computer is connected to the directory server, if not get a proxy node. */
    if([self checkServerStatus:server.serverName]){
        node = [self getServerNode:server.serverName];
    }else{
        node = [self getRemServerNode:server];
    }
    
    if(!node){
        SET_ERROR(1, ODUMCantConnectToNodeMsg);
        goto nsxpc_return;
    }
    [node setCredentialsWithRecordType:nil recordName:server.diradminName password:server.diradminPass error:&error];
    
    if(error){
        SET_ERROR(1, ODUMCantAuthenicateMsg);
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
    
    /* see if computer is connected to the directory server, if not get a proxy node. */
    if([self checkServerStatus:server.serverName]){
        node = [self getServerNode:server.serverName];
    }else{
        node = [self getRemServerNode:server];
    }
    
    if(!node){
        SET_ERROR(1, ODUMCantConnectToNodeMsg);
        goto nsxpc_return;

    }
    [node setCredentialsWithRecordType:nil recordName:server.diradminName password:server.diradminPass error:&error];
    
    if(error){
        SET_ERROR(1, ODUMCantAuthenicateMsg);
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

    /* see if computer is connected to the directory server, if not get a proxy node. */
    if([self checkServerStatus:server.serverName]){
        node = [self getServerNode:server.serverName];
    }else{
        node = [self getRemServerNode:server];
    }
    
    if(!node){
        SET_ERROR(1, ODUMCantConnectToNodeMsg);
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

    
    /* see if computer is connected to the directory server, if not get a proxy node. */
    if([self checkServerStatus:server.serverName]){
        node = [self getServerNode:server.serverName];
    }else{
        node = [self getRemServerNode:server];
    }
    
    if(!node){
        SET_ERROR(1, ODUMCantConnectToNodeMsg);
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
    
    /* see if computer is connected to the directory server, if not get a proxy node. */
    if([self checkServerStatus:server.serverName]){
        node = [self getServerNode:server.serverName];
    }else{
        node = [self getRemServerNode:server];
    }
    
    if(!node){
        SET_ERROR(1, ODUMCantConnectToNodeMsg);
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
    
    if([self checkServerStatus:server.serverName]){
        node = [self getServerNode:server.serverName];
    }else{
        node = [self getRemServerNode:server];
    }
    
    if(!node){
        SET_ERROR(1, ODUMCantConnectToNodeMsg);
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


-(ODNode*)getServerNode:(NSString*) serverName{
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
    if(![self getServerNode:server])
        connected = NO;
    reply(connected);
}

-(BOOL)checkServerStatus:(NSString*)server{
    BOOL connected = YES;
    if(![self getServerNode:server])
        connected = NO;
    return(connected);
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
