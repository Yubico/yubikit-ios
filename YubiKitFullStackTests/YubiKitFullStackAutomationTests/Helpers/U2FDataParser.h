//
//  U2FDataParser.h
//  YubiKitFullStackAutomationTests
//
//  Created by Conrad Ciobanica on 2018-08-14.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface U2FDataParser: NSObject

+ (NSString *)keyHandleFromRegistrationData:(NSData *)registrationData;

@end
