//
//  ODUAuthenticator.h
//  ODUserMaker
//
//  Created by Eldon on 11/18/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ODUAuthenticator;

@protocol ODUAuthenticatorDelegate <NSObject>
-(NSString*)nameOfServer:(ODUAuthenticator*)authenticator;
-(NSString*)nameOfDiradmin:(ODUAuthenticator*)authenticator;
-(NSString*)passwordForDiradmin:(ODUAuthenticator*)authenticator;
-(void)didRecieveStatusUpdate:(OSStatus)status;
-(void)didGetPassWordFromKeychain:(NSString*)password;
@end


@interface ODUAuthenticator : NSObject

@property (strong) id<ODUAuthenticatorDelegate>delegate;
@property BOOL status;
@property (strong) NSString* serverName;
@property (strong) NSString* diradminName;


-(void)authenticateToNode;
-(NSString*)getKeyChainPassword;
-(id)initWithDelegate:(id)delegate;



@end
