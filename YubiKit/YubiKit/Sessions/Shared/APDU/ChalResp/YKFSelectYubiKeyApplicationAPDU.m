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

#import "YKFSelectYubiKeyApplicationAPDU.h"
#import "YKFAPDUCommandInstruction.h"

static const NSUInteger YKFYubiKeyAIDSize = 8;
static const UInt8 YKFYubiKeyAID[YKFYubiKeyAIDSize] = {0xA0, 0x00, 0x00, 0x05, 0x27, 0x20, 0x01, 0x01};

@implementation YKFSelectYubiKeyApplicationAPDU

- (instancetype)init {
    NSData *data = [NSData dataWithBytes:YKFYubiKeyAID length:YKFYubiKeyAIDSize];
    return [super initWithCla:0x00 ins:YKFAPDUCommandInstructionSelectApplication p1:0x04 p2:0x00 data:data type:YKFAPDUTypeShort];
}

@end
