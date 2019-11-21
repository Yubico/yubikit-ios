//
//  U2FDataParser.m
//  YubiKitFullStackAutomationTests
//
//  Created by Conrad Ciobanica on 2018-08-14.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <YubiKit/YubiKit.h>
#import "U2FDataParser.h"

@implementation U2FDataParser

#pragma mark - Registration data parsing

// Registration raw message format id documented here:
// https://fidoalliance.org/specs/fido-u2f-v1.2-ps-20170411/fido-u2f-raw-message-formats-v1.2-ps-20170411.html

+ (NSString *)keyHandleFromRegistrationData:(NSData *)registrationData {
    UInt8 keyHandleLength = ((UInt8*)registrationData.bytes)[66];
    
    NSData *data = [registrationData subdataWithRange:NSMakeRange(67, keyHandleLength)];
    NSString *keyHandleString = [data ykf_websafeBase64EncodedString];
    
    return keyHandleString;
}

@end
