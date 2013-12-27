//
//  ODUSingleUser.m
//  ODUserMaker
//
//  Created by Eldon on 11/19/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUDirectoryConnection.h"
#import "ODUProgress.h"
#import "ODUError.h"
#import "OpenDirectoryService.h"
@implementation ODUDirectoryConnection

#pragma mark - Initializers
-(id)initWithServiceName:(NSString *)serviceName{
    self = [super initWithServiceName:serviceName];
    if (self) {
        self.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
        self.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
        self.exportedObject = [NSApp delegate];
        [self resume];
    }
    return self;
}

-(id)initWithQueryDelegate:(id<ODUSQueryDelegate>)delegate{
    self = [self initWithServiceName:kDirectoryServiceName];
    if(self){
        _queryDelegate = delegate;
    }
    return self;
}

-(id)initWithAuthDelegate:(id<ODUAuthenticatorDelegate>)delegate{
    self = [self initWithServiceName:kDirectoryServiceName];
    if(self){
        _authDelegate = delegate;
    }
    return self;
}

-(id)initConnection{
    self = [self initWithServiceName:kDirectoryServiceName];
    return self;
}

#pragma mark - Directory Edit
-(void)addUser:(ODUser*)user andGroups:(NSArray *)groups reply:(void (^)(NSError *))reply{
    [[self remoteObjectProxyWithErrorHandler:^(NSError *error) {
        if(error)NSLog(@"add user xpc error: %@",error.localizedDescription);
    }] addSingleUser:user withGroups:groups withReply:^(NSError *error){
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            reply(error);
        }];
        [self invalidate];
    }];
}

-(void)importUserList:(ODUserList*)users withGroups:(NSArray*)groups reply:(void (^)(NSError *))reply{
    [[self remoteObjectProxy] addListOfUsers:users withGroups:groups withReply:^(NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            reply(error);
        }];
        [self invalidate];
    }];
}

-(void)resetPassword:(ODUser*)user reply:(void (^)(NSError *error))reply{
    [[self remoteObjectProxy] resetUserPassword:user withReply:^(NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            reply(error);
        }];
        [self invalidate];
    }];
    
}

#pragma mark - Server Status
-(void)checkServerStatus{
    ODServer* server = [ODServer new];
    server.diradminName = [_authDelegate nameOfDiradmin];
    server.diradminPass = [_authDelegate passwordForDiradmin];
    server.directoryServer = [_authDelegate nameOfServer];
    
    [[self remoteObjectProxy] checkServerStatus:server withReply:^(OSStatus status){
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_authDelegate didRecieveStatusUpdate:status];
        }];
        [self invalidate];
    }];
}

#pragma mark - Record Query
-(void)getUserList{
    [[self remoteObjectProxyWithErrorHandler:^(NSError *error) {
        NSLog(@"%@",error.localizedDescription);
    }]getUserListFromServer:^(NSArray *array, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_queryDelegate didGetDSUserList:array];
        }];
        [self invalidate];
    }];
}

-(void)getGroupList{
    [[self remoteObjectProxyWithErrorHandler:^(NSError *error) {
        NSLog(@"%@",error.localizedDescription);
    }]getGroupListFromServer:^(NSArray *array, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_queryDelegate didGetDSGroupList:array];
        }];
        [self invalidate];
    }];
}

-(void)getPresetList{
    [[self remoteObjectProxyWithErrorHandler:^(NSError *error) {
        NSLog(@"%@",error.localizedDescription);
    }]getPresetsListFromServer:^(NSArray *array, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_queryDelegate didGetDSUserPresets:array];
        }];
        [self invalidate];
    }];
}

-(void)getSettingsForPreset{
    NSString *preset = [_queryDelegate nameOfPreset];
    [[self remoteObjectProxyWithErrorHandler:^(NSError *error) {
        NSLog(@"error %@",error.localizedDescription);
    }]getSettingsForPreset:preset withReply:^(ODPreset *preset, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_queryDelegate didGetSettingsForPreset:preset];
        }];
        [self invalidate];
    }];
}

#pragma mark - Class Methods / Convenience Accessors;
+(void)cancelImport{
    ODUDirectoryConnection* service = [[ODUDirectoryConnection alloc]initConnection];
    [[service remoteObjectProxyWithErrorHandler:^(NSError *error) {
        NSLog(@"%@",error.localizedDescription);
    }] cancelImportStatus:^(BOOL canceled) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[NSApp delegate] performSelectorOnMainThread:@selector(stopProgressPanel)
                                               withObject:nil waitUntilDone:NO];
        }];
        [service invalidate];
    }];
}

+(void)getUserList:(id<ODUSQueryDelegate>)delegate{
    ODUDirectoryConnection* service = [[ODUDirectoryConnection alloc]initConnection];
    service.queryDelegate = delegate;
    [service getUserList];
}

+(void)getGroupList:(id<ODUSQueryDelegate>)delegate{
    ODUDirectoryConnection* service = [[ODUDirectoryConnection alloc]initConnection];
    service.queryDelegate = delegate;
    [service getGroupList];
}

+(void)getPresetList:(id<ODUSQueryDelegate>)delegate{
    ODUDirectoryConnection* service = [[ODUDirectoryConnection alloc]initConnection];
    service.queryDelegate = delegate;
    [service getPresetList];
}



@end
