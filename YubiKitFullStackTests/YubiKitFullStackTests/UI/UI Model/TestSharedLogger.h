//
//  TestSharedLogger.h
//  YubiKitFullStackTests
//
//  Created by Conrad Ciobanica on 2018-05-17.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoggingViewController.h"

@interface TestSharedLogger : NSObject

@property (nonatomic, readonly, class) TestSharedLogger *shared;
@property (nonatomic, weak) LoggingViewController *loggingViewController;

- (void)logSepparator;

- (void)logMessage:(NSString *)message, ...;
- (void)logError:(NSString *)format, ...;
- (void)logSuccess:(NSString *)format, ...;

- (void)logCondition:(BOOL)condition onSuccess:(NSString *)successMessage onFailure:(NSString *)failureMessage;

@end
