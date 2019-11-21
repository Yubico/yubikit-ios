//
//  AppDelegate.m
//  YubiKitFullStackTests
//
//  Created by Conrad Ciobanica on 2018-05-15.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <YubiKit/YubiKit.h>
#import "AppDelegate.h"
#import "AppStateController.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor greenColor];
    [self.window makeKeyAndVisible];
    
    // Start YubiKit
    id<YubiKitManagerProtocol> sharedManager = YubiKitManager.shared;
    NSAssert(sharedManager, @"Error in starting YubiKit");
    [sharedManager.accessorySession startSession];
    
    // Shows the right UI for the target
    [AppStateController setupInitialState];
    
    return YES;
}

@end
