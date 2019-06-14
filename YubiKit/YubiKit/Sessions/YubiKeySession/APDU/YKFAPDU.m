// Copyright 2018-2019 Yubico AB
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "YKFAPDU.h"
#import "YKFKeyConnectionController.h"
#import "YKFNSMutableDataAdditions.h"
#import "YKFAssert.h"

@interface YKFAPDU()

@property (nonatomic, readwrite) NSData *apduData;

@end

@implementation YKFAPDU

- (instancetype)initWithCla:(UInt8)cla ins:(UInt8)ins p1:(UInt8)p1 p2:(UInt8)p2 data:(NSData *)data type:(YKFAPDUType)type {
    if (data.length) {
        if (type == YKFAPDUTypeShort) {
            YKFAssertAbortInit(data.length <= UINT8_MAX)
        } else if (type == YKFAPDUTypeExtended) {
            YKFAssertAbortInit(data.length <= UINT16_MAX)
        }
    }
    
    self = [super init];
    if (self) {
        switch (type) {
            case YKFAPDUTypeShort:
                self.apduData = [self apduWithCla:cla ins:ins p1:p1 p2:p2 data:data];
                break;
            case YKFAPDUTypeExtended:
            default:
                self.apduData = [self extendedApduWithCla:cla ins:ins p1:p1 p2:p2 data:data];
                break;
        }
    }
    return self;
}

- (NSData *)apduWithCla:(UInt8)cla ins:(UInt8)ins p1:(UInt8)p1 p2:(UInt8)p2 data:(NSData*)data {
    NSMutableData *command = [[NSMutableData alloc] init];
    
    [command ykf_appendByte:0x00];  // YLP iAP2 Signal
    [command ykf_appendByte:cla];   // APDU CLA
    [command ykf_appendByte:ins];   // APDU INS
    [command ykf_appendByte:p1];    // APDU P1
    [command ykf_appendByte:p2];    // APDU P2

    if (data.length) {
        UInt8 length = data.length;
        [command ykf_appendByte:length];    // LenLc
        [command appendData:data];          // Data
    }

    return command;
}

- (NSData *)extendedApduWithCla:(UInt8)cla ins:(UInt8)ins p1:(UInt8)p1 p2:(UInt8)p2 data:(NSData *)data {
    NSMutableData *command = [[NSMutableData alloc] init];
    
    [command ykf_appendByte:0x00];  // YLP iAP2 Signal
    [command ykf_appendByte:cla];   // APDU CLA
    [command ykf_appendByte:ins];   // APDU INS
    [command ykf_appendByte:p1];    // APDU P1
    [command ykf_appendByte:p2];    // APDU P2
    
    if (data.length) {
        UInt8 lengthHigh = data.length / 256;
        UInt8 lengthLow = data.length % 256;
        [command ykf_appendByte:0x00];           // APDU Zero
        [command ykf_appendByte:lengthHigh];     // LenH
        [command ykf_appendByte:lengthLow];      // LenL
        [command appendData:data];               // Data
    } else {
        [command ykf_appendByte:0x00];           // APDU Zero
        [command ykf_appendByte:0x00];           // LenH
        [command ykf_appendByte:0x00];           // LenL
    }
    
    return command;
}

- (nullable instancetype)initWithData:(nonnull NSData *)data {
    YKFAssertAbortInit(data.length);
    self = [super init];
    if (self) {
        NSMutableData *tempBuffer = [[NSMutableData alloc] initWithCapacity:data.length + 1];
        [tempBuffer ykf_appendByte:0x00]; // Append the YLP iAP2 Signal
        [tempBuffer appendData:data];
        
        self.apduData = [tempBuffer copy];
    }
    return self;
}

@end
