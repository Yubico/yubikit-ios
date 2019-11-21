//
//  OTPValidationWebServiceResponse.h
//  YubiKitFullStackAutomationTests
//
//  Created by Conrad Ciobanica on 2018-08-09.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTPValidationWebServiceResponse : NSObject

@property (nonatomic, assign, readonly) BOOL isValid;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
