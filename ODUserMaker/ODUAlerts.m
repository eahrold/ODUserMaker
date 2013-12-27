//
//  ODUAlerts.m
//  ODUserMaker
//
//  Created by Eldon on 11/12/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "ODUAlerts.h"
@implementation ODUAlerts

//-------------------------------------------
//  Progress Panel and Alert
//-------------------------------------------

+ (void)showErrorAlert:(NSError *)error {
    [[NSAlert alertWithError:error] beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow]
                                               modalDelegate:self
                                              didEndSelector:nil
                                                 contextInfo:nil];
}

+ (void)showAlert:(NSString *)alert withDescription:(NSString *)msg {
    if(!msg){
        msg = @"";
    }
    [[NSAlert alertWithMessageText:alert defaultButton:@"OK"
                   alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@",msg]
     
     beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow]
     modalDelegate:self
     didEndSelector:nil
     contextInfo:nil];
}


@end
