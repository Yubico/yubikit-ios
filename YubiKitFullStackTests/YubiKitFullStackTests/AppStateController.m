//
//  AppStateController.m
//  YubiKitFullStackManualTests
//
//  Created by Conrad Ciobanica on 2018-06-20.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppStateController.h"
#import "Configuration.h"

@implementation AppStateController

+ (void)setupInitialState {
    Configuration *configuration = [[Configuration alloc] init];
    
    if (configuration.automationRunning) {
        [self showLogsStoryboard];
    }
    else {
        [self showMainStoryboard];
    }
}

#pragma mark - UI setup

+ (void)showLogsStoryboard {
    [self showStoryboardWithName:@"Logs"];
}

+ (void)showMainStoryboard {
    [self showStoryboardWithName:@"Main"];
}

+ (void)showStoryboardWithName:(NSString *)name {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:name bundle:nil];
    UIViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.view.frame = window.bounds;
    window.rootViewController = viewController;
}

@end
