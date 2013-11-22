//
//  ODUDSQuery.h
//  ODUserMaker
//
//  Created by Eldon on 11/12/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Server,User,ODUController,ODUDSQuery;


@protocol ODUSQueryDelegate <NSObject>
-(NSString*)nameOfPreset;
-(void)didGetDSUserList:(NSArray*)dsusers;
-(void)didGetDSGroupList:(NSArray*)dsgroups;
-(void)didGetDSUserPresets:(NSArray*)dspresets;
-(void)didGetSettingsForPreset:(NSDictionary*)settings;
@end


@interface ODUDSQuery : NSObject
@property (weak) id<ODUSQueryDelegate>delegate;
-(id)initWithDelegate:(id)delegate;

-(void)getDSUserList;
-(void)getDSGroupList;
-(void)getDSUserPresets;
-(void)getSettingsForPreset;

@end
