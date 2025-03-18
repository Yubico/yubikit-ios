// Copyright Yubico AB
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

#import "YKFSCPState.h"
#import "YKFSCPSessionKeys.h"
#import "YKFNSDataAdditions+Private.h"

@implementation YKFSCPState

- (instancetype)initWithSessionKeys:(YKFSCPSessionKeys *)sessionKeys macChain:(NSData *)macChain {
    self = [super init];
    if (self) {
        _sessionKeys = sessionKeys;
        _macChain = [macChain mutableCopy];
        _encCounter = 1;
    }
    return self;
}

- (NSData *)encrypt:(NSData *)data error:(NSError **)error {
    NSLog(@"👾 encrypt %@ using %@", [data ykf_hexadecimalString], self);
    
    NSData *paddedData = [data ykf_bitPadded];
    NSMutableData *ivData = [NSMutableData dataWithLength:12];
    uint32_t encCounterBE = CFSwapInt32HostToBig(self.encCounter);
    [ivData appendBytes:&encCounterBE length:sizeof(encCounterBE)];
    self.encCounter += 1;
    
    NSData *iv = [ivData ykf_cryptOperation:kCCEncrypt algorithm:kCCAlgorithmAES mode:kCCModeECB key:self.sessionKeys.senc iv:nil];
    if (!iv) return nil;

    return [paddedData ykf_cryptOperation:kCCEncrypt algorithm:kCCAlgorithmAES mode:kCCModeCBC key:self.sessionKeys.senc iv:iv];
}

- (NSData *)decrypt:(NSData *)data error:(NSError **)error {
    NSLog(@"decrypt: %@", [data ykf_hexadecimalString]);
    
    NSMutableData *ivData = [NSMutableData data];
    uint8_t paddingByte = 0x80;
    [ivData appendBytes:&paddingByte length:1];
    [ivData appendData:[NSMutableData dataWithLength:11]];
    uint32_t encCounterBE = CFSwapInt32HostToBig(self.encCounter - 1);
    [ivData appendBytes:&encCounterBE length:sizeof(encCounterBE)];
    
    NSData *iv = [ivData ykf_cryptOperation:kCCEncrypt algorithm:kCCAlgorithmAES mode:kCCModeECB key:self.sessionKeys.senc iv:nil];
    if (!iv) return nil;
    
    NSData *decrypted = [data ykf_cryptOperation:kCCDecrypt algorithm:kCCAlgorithmAES mode:kCCModeCBC key:self.sessionKeys.senc iv:iv];

    if (!decrypted) return nil;

    NSLog(@"decrypted: %@", [decrypted ykf_hexadecimalString]);
    return [self unpadData:decrypted];
}

- (NSData * _Nullable)unpadData:(NSData *)data {
    NSInteger lastNonZeroIndex = -1;
    for (NSInteger i = data.length - 1; i >= 0; i--) {
        uint8_t byte;
        [data getBytes:&byte range:NSMakeRange(i, 1)];
        if (byte != 0x00) {
            lastNonZeroIndex = i;
            break;
        }
    }
    
    if (lastNonZeroIndex == -1) return nil;
    
    uint8_t lastByte;
    [data getBytes:&lastByte range:NSMakeRange(lastNonZeroIndex, 1)];
    if (lastByte == 0x80) {
        return [data subdataWithRange:NSMakeRange(0, lastNonZeroIndex)];
    }
    
    return nil;
}

- (NSData *)macWithData:(NSData *)data error:(NSError **)error {
    NSMutableData *message = [NSMutableData dataWithData:self.macChain];
    [message appendData:data];

    self.macChain = [[message ykf_aesCMACWithKey:self.sessionKeys.smac] mutableCopy];
    if (!self.macChain) return nil;
    
    return [self.macChain subdataWithRange:NSMakeRange(0, 8)];
}

- (NSData *)unmacWithData:(NSData *)data sw:(uint16_t)sw error:(NSError **)error {
    NSMutableData *message = [NSMutableData dataWithData:[data subdataWithRange:NSMakeRange(0, data.length - 8)]];
    uint16_t swBigEndian = CFSwapInt16HostToBig(sw);
    [message appendBytes:&swBigEndian length:sizeof(swBigEndian)];

    NSMutableData *macChainAndMessage = [self.macChain mutableCopy];
    [macChainAndMessage appendData:message];
    NSData *rmac = [[macChainAndMessage ykf_aesCMACWithKey:self.sessionKeys.srmac] subdataWithRange:NSMakeRange(0, 8)];
    if (!rmac) return nil;
    
    NSData *expectedMac = [data subdataWithRange:NSMakeRange(data.length - 8, 8)];
    if (![rmac ykf_constantTimeCompareWithData:expectedMac]) {
        if (error) {
            *error = [NSError errorWithDomain:@"SCPStateError" code:101 userInfo:@{NSLocalizedDescriptionKey: @"MAC mismatch"}];
        }
        return nil;
    }
    
    return [message subdataWithRange:NSMakeRange(0, message.length - 2)];
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"SCPState(sessionKeys: %@, macChain: %@, encCounter: %u)",
            self.sessionKeys,
            [self.macChain ykf_hexadecimalString],
            self.encCounter];
}

@end
