//
//  Configuration.m
//  YubiKitFullStackAutomationTests
//
//  Created by Conrad Ciobanica on 2018-06-21.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import "Configuration.h"

@implementation Configuration

- (BOOL)automationRunning {
    NSDictionary* environment = [[NSProcessInfo processInfo] environment];
    return [environment objectForKey:@"AUTOMATION_RUNNING"] != nil;
}

@end
