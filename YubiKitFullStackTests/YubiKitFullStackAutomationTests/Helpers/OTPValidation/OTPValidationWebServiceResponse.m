//
//  OTPValidationWebServiceResponse.m
//  YubiKitFullStackAutomationTests
//
//  Created by Conrad Ciobanica on 2018-08-09.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import "OTPValidationWebServiceResponse.h"

@interface OTPValidationWebServiceResponse()

@property (nonatomic) NSDictionary *responseDictionary;

@end

@implementation OTPValidationWebServiceResponse

- (BOOL)isValid {
    return [self.responseDictionary[@"status"] isEqualToString:@"OK"];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.responseDictionary = dictionary;
    }
    return self;
}

@end
