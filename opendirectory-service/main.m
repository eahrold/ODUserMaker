//
//  main.m
//  uploader-service
//
//  Created by Eldon Ahrold on 7/13/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#include <Foundation/Foundation.h>
#import "OpenDirectoryService.h"

int main(int argc, const char *argv[])
{
    // Get the singleton service listener object.
    NSXPCListener *serviceListener = [NSXPCListener serviceListener];
    
    // Configure the service listener with a delegate.
    DirectoryServer *sharedDirectoryServer = [DirectoryServer sharedDirectoryServer];
    serviceListener.delegate = sharedDirectoryServer;
    
    // Resume the listener. At this point, NSXPCListener will take over the execution of this service, managing its lifetime as needed.
    [serviceListener resume];
    
	return 0;
}
