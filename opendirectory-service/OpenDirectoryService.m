//
//  OpenDirectoryService.m
//  ODUserMaker
//
//  Created by Eldon Ahrold on 7/21/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <OpenDirectory/OpenDirectory.h>
#import "OpenDirectoryService.h"
#import "AppProgress.h"


@implementation OpenDirectoryService

-(void)addGroups:(NSArray*)groups toServer:(Server*)server withReply:(void (^)(NSError *))reply{
    NSError *error = nil;
    ODNode *node;
    
    /* see if computer is connected to the directory server, if not get a proxy node. */
    if([self checkServerStatus:server.serverName]){
        node = [self getServerNode:server.serverName];
    }else{
        node = [self getRemServerNode:server];
    }
    [node setCredentialsWithRecordType:nil recordName:server.diradminName password:server.diradminPass error:&error];
    
    for(NSDictionary* g in groups){
        NSString* groupName = [ g objectForKey:@"group"];
        NSArray* userNames = [ g objectForKey:@"users"];
        ODRecord* groupRecord = [self getGroupRecord:groupName withNode:node];
        
        for(NSString* u in userNames){
            NSLog(@"adding %@ to %@",u,groupName);
            ODRecord* userRecord = [self getUserRecord:u withNode:node];
            if(userRecord){
                NSError* err;
                [groupRecord addMemberRecord:userRecord error:&err];
                if(err)
                    NSLog(@"Error:%@",[err localizedDescription]);
            }
        }
    }
    reply(error);
}


-(void)addUser:(User *)user toGroup:(NSArray *)group toServer:(Server *)server withReply:(void (^)(NSError *error))reply{
    NSError *error;
    ODNode *node;
    
    /* see if computer is connected to the directory server, if not get a proxy node. */
    if([self checkServerStatus:server.serverName]){
        node = [self getServerNode:server.serverName];
    }else{
        node = [self getRemServerNode:server];
    }
    
    ODRecord* userRecord = [self getUserRecord:user.userName withNode:node];
    
    [node setCredentialsWithRecordType:nil recordName:server.diradminName password:server.diradminPass error:&error];
    
    for(NSString* g in group){
        ODRecord* groupRecord = [self getGroupRecord:g withNode:node];
        [groupRecord addMemberRecord:userRecord error:&error];
    }
 
    reply(error);
}

-(void)getUserPresets:(Server*)server withReply:(void (^)(NSArray *userPreset,NSError *error))reply{
    NSError *error;
    ODNode *node;
    if([self checkServerStatus:server.serverName]){
        node = [self getServerNode:server.serverName];
    }else{
        node = [self getRemServerNode:server];
    }
    
    ODQuery *query = [ODQuery  queryWithNode: node
                                forRecordTypes: kODRecordTypePresetUsers
                                     attribute: kODAttributeTypeRecordName
                                     matchType: kODMatchAny
                                   queryValues: nil
                              returnAttributes: kODAttributeTypeStandardOnly
                                maximumResults: 0
                                         error: &error];
    
    NSArray *odArray = [[NSArray alloc]init];
    odArray = [query resultsAllowingPartial:NO error:&error];
    
    NSMutableArray *userPresets = [NSMutableArray arrayWithCapacity:[odArray count]];
    ODRecord *record;
    
    for (record in odArray) {
        NSError *err;
        NSArray *recordName = [record valuesForAttribute:kODAttributeTypeRecordName error:&err];
        
        if ([recordName count]) {
            [userPresets addObject:[recordName objectAtIndex:0]];
        }
    }
    reply(userPresets,error);
}


-(void)getGroupListFromServer:(Server*)server withReply:(void (^)(NSArray *groupList,NSError *error))reply{
    NSError *error;
    ODNode *node;
    if([self checkServerStatus:server.serverName]){
        node = [self getServerNode:server.serverName];
    }else{
        node = [self getRemServerNode:server];
    }
    
    ODQuery *query = [ODQuery  queryWithNode: node
                              forRecordTypes: kODRecordTypeGroups
                                   attribute: kODAttributeTypeRecordName
                                   matchType: kODMatchAny
                                 queryValues: nil
                            returnAttributes: kODAttributeTypeStandardOnly
                              maximumResults: 0
                                       error: &error];
    
    NSArray *odArray = [[NSArray alloc]init];
    odArray = [query resultsAllowingPartial:NO error:&error];
    
    NSMutableArray *groupList = [NSMutableArray arrayWithCapacity:[odArray count]];
    ODRecord *record;
    
    for (record in odArray) {
        NSError *err;
        NSArray *recordName = [record valuesForAttribute:kODAttributeTypeRecordName error:&err];
        
        if ([recordName count]) {
            [groupList addObject:[recordName objectAtIndex:0]];
        }
    }
    reply(groupList,error);
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
    
    NSArray *odArray = [[NSArray alloc]init];
    odArray = [query resultsAllowingPartial:NO error:nil];
    
    record = [odArray objectAtIndex:0];
    
    return record;
    
}

-(ODRecord*)getUserRecord:(NSString*)user withNode:(ODNode*)node{
    ODRecord* record;
    ODQuery *query = [ODQuery  queryWithNode: node
                              forRecordTypes: kODRecordTypeUsers
                                   attribute: kODAttributeTypeRecordName
                                   matchType: kODMatchEqualTo
                                 queryValues: user
                            returnAttributes: kODAttributeTypeStandardOnly
                              maximumResults: 1
                                       error: nil];
    
    NSArray *odArray = [[NSArray alloc]init];
    odArray = [query resultsAllowingPartial:NO error:nil];
    
    record = [odArray objectAtIndex:0];
    
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
