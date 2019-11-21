//
//  LoggingViewController.h
//  YubiKitFullStackTests
//
//  Created by Conrad Ciobanica on 2018-05-16.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoggingViewController : UIViewController

// This is not the best place for this property but to keep the design simple this is good enough.
@property (nonatomic, readonly) NSString *otp;

- (void)log:(NSString *)message;

- (void)logError:(NSString *)message;
- (void)logSuccess:(NSString *)message;

@end
