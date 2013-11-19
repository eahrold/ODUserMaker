//
//  ODUDSQuery.m
//  ODUserMaker
//
//  Created by Eldon on 11/12/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//
#import "ODUDelegate.h"
#import "ODUDSQuery.h"
#import "OpenDirectoryService.h"
#import "FileService.h"

#import "ODCommonHeaders.h"
#import "ODUController.h"

@implementation ODUDSQuery

-(id)initWithDelegate:(id)delegate{
    self = [super init];
    if(self){
        _delegate = delegate;
    }
    return self;
}

-(void)getDSGroupList{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = [NSApp delegate];
    [connection resume];
    [[connection remoteObjectProxy] getGroupListFromServer:^(NSArray *gArray, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(!error){
                [_delegate didGetDSGroupList:gArray];
            }
        }];
        [connection invalidate];
    }];
}

-(void)getDSUserList{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = [NSApp delegate] ;
    [connection resume];
    [[connection remoteObjectProxy] getUserListFromServer:^(NSArray *uArray, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(!error){
                NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending: YES];
                NSArray* userList = [uArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
                [_delegate didGetDSUserList:userList];
            }
        }];
        [connection invalidate];
    }];
}

-(void)getDSUserPresets{
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = [NSApp delegate];
    [connection resume];
    [[connection remoteObjectProxy] getUserPresets:^(NSArray *pArray, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(!error){
                [_delegate didGetDSUserPresets:pArray];
            }
        }];
        [connection invalidate];
    }];
}

-(void)getSettingsForPreset{
    NSString* presetName = [_delegate nameOfPreset];
    if(!presetName){
        return;
    }
    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithServiceName:kDirectoryServiceName];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OpenDirectoryService)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Progress)];
    connection.exportedObject = [NSApp delegate];
    [connection resume];
    [[connection remoteObjectProxy] getSettingsForPreset:presetName withReply:^(NSDictionary *settings, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(!error){
                [_delegate didGetSettingsForPreset:settings];
            }
        }];
        [connection invalidate];
    }];

}


@end
