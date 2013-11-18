//
//  ODUAuthenticator.m
//  ODUserMaker
//
//  Created by Eldon on 11/18/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUAuthenticator.h"
#import "SSKeychain.h"
#import "OpenDirectoryService.h"
#import "ODCommonHeaders.h"

@implementation ODUAuthenticator{
    NSString* diradminPass;
}
@synthesize serverName,diradminName;

-(id)initWithDelegate:(id)delegate{
    self = [super init];
    if(self){
        _delegate = delegate;
    }
    return self;
}

-(void)authenticateToNode{
    NSError* error;
    
    serverName = [_delegate nameOfServer:self];
    diradminName = [_delegate nameOfDiradmin:self];
    diradminPass = [_delegate passwordForDiradmin:self];
    
    if(!diradminPass){
        diradminPass = [self getKeyChainPassword];
    }
    
    /* don't bother checking untill everything is in place */
    if(!serverName||!diradminName||!diradminPass){
        error = [ODUserError errorWithCode:ODUMFieldsMissing];
        [_delegate didRecieveStatusUpdate:ODUNoNode];
        return;
    }
    
    Server* server = [Server new];
    
    server.serverName = serverName;
    server.diradminName = diradminName;
    server.diradminPass = diradminPass;
        
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = _delegate;
    [connection resume];
    [[connection remoteObjectProxy] checkServerStatus:server withReply:^(OSStatus status)  {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_delegate didRecieveStatusUpdate:status];
            if(status > -1)[self setKeyChainPassword];
         }];
        [connection invalidate];
    }];
}

-(NSString*)getKeyChainPassword{
    NSError* error;
    serverName = [_delegate nameOfServer:self];
    diradminName = [_delegate nameOfDiradmin:self];
    
    NSString* kcAccount = [NSString stringWithFormat:@"%@:%@",diradminName ,serverName];
    NSString* kcPass = [SSKeychain passwordForService:
                        [[NSBundle mainBundle] bundleIdentifier] account:kcAccount error:&error];
    
    if(kcPass)[_delegate didGetPassWordFromKeychain:kcPass];
    
    if(error)return nil;
    return kcPass;
}

-(void)setKeyChainPassword{
    if(diradminPass){
        NSString* kcAccount = [NSString stringWithFormat:@"%@:%@",diradminName,serverName];
        [SSKeychain setPassword:diradminPass forService:[[NSBundle mainBundle] bundleIdentifier] account:kcAccount];
    }
}

@end
