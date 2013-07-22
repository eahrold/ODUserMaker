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


@implementation DirectoryServer

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


-(ODNode*)getServerNode:(NSString*) serverName{
    ODSession *session = [ODSession defaultSession];
    
    NSError *err;
    NSString *ldap = [NSString stringWithFormat:@"/LDAPv3/%@",serverName];
    ODNode *node = [ODNode nodeWithSession:session name:ldap error:&err];
        
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
    
    NSError *err;
    NSString *ldap = [NSString stringWithFormat:@"/LDAPv3/127.0.0.1"];
    ODNode *node = [ODNode nodeWithSession:session name:ldap error:&err];
    
    if(!node){
        return nil;
    }
    return node;
}


//---------------------------------
//  Singleton and ListenerDelegate
//---------------------------------

+ (DirectoryServer*)sharedDirectoryServer {
    static dispatch_once_t onceToken;
    static DirectoryServer* shared;
    dispatch_once(&onceToken, ^{
        shared = [DirectoryServer new];
    });
    return shared;
}


// Implement the one method in the NSXPCListenerDelegate protocol.
- (BOOL)listener:(NSXPCListener*)listener shouldAcceptNewConnection:(NSXPCConnection*)newConnection {
    
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(DirectoryServer)];
    newConnection.exportedObject = self;
    
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    self.xpcConnection = newConnection;
    
    [newConnection resume];
    
    return YES;
}


@end
