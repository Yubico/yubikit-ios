//
//  TestSharedLogger.m
//  YubiKitFullStackTests
//
//  Created by Conrad Ciobanica on 2018-05-17.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import "TestSharedLogger.h"

@implementation TestSharedLogger

static TestSharedLogger *sharedInstance = nil;

+ (TestSharedLogger *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TestSharedLogger alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Logging

- (void)logSepparator {
    NSString *uiLogString = @"------------------------";
    [self.loggingViewController log:uiLogString];
}

- (void)logMessage:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    
    // Log to console
    NSLogv(format, args);
    
    // Log to UI
    NSString *uiLogString = [[NSString alloc] initWithFormat:format arguments:args];
    [self.loggingViewController log:uiLogString];    
    
    va_end(args);
}

- (void)logError:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    
    // Log to console
    NSLogv(format, args);
    
    // Log to UI
    NSString *uiLogString = [[NSString alloc] initWithFormat:format arguments:args];
    [self.loggingViewController logError:uiLogString];
    
    va_end(args);
}

- (void)logSuccess:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    
    // Log to console
    NSLogv(format, args);
    
    // Log to UI
    NSString *uiLogString = [[NSString alloc] initWithFormat:format arguments:args];
    [self.loggingViewController logSuccess:uiLogString];
    
    va_end(args);
}

- (void)logCondition:(BOOL)condition onSuccess:(NSString *)successMessage onFailure:(NSString *)failureMessage {
    if (condition) {
        [self logSuccess:successMessage];
    } else {
        [self logError:failureMessage];
    }
}

@end
