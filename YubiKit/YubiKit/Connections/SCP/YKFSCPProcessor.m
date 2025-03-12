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

#import "YKFNSDataAdditions+Private.h"
#import "YKFSCPKeyParamsProtocol.h"
#import "YKFSCP03KeyParams.h"
#import "YKFSCP11KeyParams.h"
#import "YKFSCPKeyRef.h"
#import "YKFSCPState.h"
#import "YKFSCPStaticKeys.h"
#import "YKFSCPSessionKeys.h"
#import "YKFAPDU+Private.h"
#import "YKFAPDU.h"
#import "YKFSCPProcessor.h"

@interface YKFSCPProcessor ()
@property (nonatomic, strong) YKFSCPState *state;
@end

@implementation YKFSCPProcessor

- (instancetype)initWithState:(YKFSCPState *)state {
    self = [super init];
    if (self) {
        self.state = state;
    }
    return self;
}

+ (void)processorWithSCPKeyParams:(id<YKFSCPKeyParamsProtocol> _Nonnull)scpKeyParams
                 sendRemainingIns:(YKFSmartCardInterfaceSendRemainingIns)sendRemainingIns
          usingSmartCardInterface:(YKFSmartCardInterface *)smartCardInterface
                       completion:(YKFSCPProcessorCompletionBlock _Nonnull)completion {
    if ([scpKeyParams isKindOfClass:[YKFSCP03KeyParams class]]) {
        YKFSCP03KeyParams *scp03KeyParams = (YKFSCP03KeyParams *)scpKeyParams;
        NSData *hostChallenge = [NSData ykf_randomDataOfSize:8];
        NSLog(@"Send challenge: %@", [hostChallenge ykf_hexadecimalString]);
        
        uint8_t insInitializeUpdate = 0x50;
        YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0x80 ins:insInitializeUpdate p1:scp03KeyParams.keyRef.kvn p2:0x00 data:hostChallenge type:YKFAPDUTypeShort];
        
        [smartCardInterface executeCommand:apdu sendRemainingIns:sendRemainingIns completion:^(NSData * _Nullable result, NSError * _Nullable error) {
            if (error) {
                completion(nil, error);
                return;
            }
            
            if (result.length < 29) { // Ensure sufficient length
                if (completion) {
                    completion(nil, [NSError errorWithDomain:@"SCPErrorDomain" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"Unexpected result"}]);
                }
                return;
            }
            
            NSData *diversificationData = [result subdataWithRange:NSMakeRange(0, 10)];
            NSData *keyInfo = [result subdataWithRange:NSMakeRange(10, 3)];
            NSData *cardChallenge = [result subdataWithRange:NSMakeRange(13, 8)];
            NSData *cardCryptogram = [result subdataWithRange:NSMakeRange(21, 8)];
            
            NSMutableData *context = [NSMutableData dataWithData:hostChallenge];
            [context appendData:cardChallenge];
            
            YKFSCPSessionKeys *sessionKeys = [scp03KeyParams.staticKeys deriveWithContext:context];
            
            NSData *genCardCryptogram = [YKFSCPStaticKeys deriveKeyWithKey:sessionKeys.smac t:0x00 context:context l:0x40 error:&error];
            
            if (![genCardCryptogram ykf_constantTimeCompareWithData:cardCryptogram]) {
                if (completion) {
                    completion(nil, [NSError errorWithDomain:@"SCPErrorDomain" code:-3 userInfo:@{NSLocalizedDescriptionKey: @"Invalid card cryptogram"}]);
                }
                return;
            }
            
            NSData *hostCryptogram = [YKFSCPStaticKeys deriveKeyWithKey:sessionKeys.smac t:0x01 context:context l:0x40 error:&error];
            
            YKFSCPState *state = [[YKFSCPState alloc] initWithSessionKeys:sessionKeys macChain:[NSMutableData dataWithLength:16]];
            YKFSCPProcessor *processor = [[YKFSCPProcessor alloc] initWithState:state];
            
            YKFAPDU *finalizeApdu = [[YKFAPDU alloc] initWithCla:0x84 ins:0x82 p1:0x33 p2:0x00 data:hostCryptogram type:YKFAPDUTypeExtended];
            
            [processor executeCommand:finalizeApdu sendRemainingIns:sendRemainingIns encrypt:NO usingSmartCardInterface:smartCardInterface completion:^(NSData * _Nullable result, NSError * _Nullable error) {
                if (error) {
                    completion(nil, error);
                    return;
                }
                completion(processor, nil);
            }];
        }];
        
    }
    
    YKFSCP11KeyParams *scp11KeyParams = (YKFSCP11KeyParams *)scpKeyParams;
    if ([scpKeyParams isKindOfClass:[YKFSCP11KeyParams class]]) {
        
        
        
    }
    
    
}



- (void)executeCommand:(YKFAPDU *)apdu
      sendRemainingIns:(YKFSmartCardInterfaceSendRemainingIns)sendRemainingIns
               encrypt:(BOOL)encrypt
usingSmartCardInterface:(YKFSmartCardInterface *)smartCardInterface
            completion:(YKFSmartCardInterfaceResponseBlock)completion {
    
    NSLog(@"👾 process %@, %@", apdu, self.state);
    
    NSData *data;
    if (encrypt) {
        NSError *error = nil;
        data = [self.state encrypt:apdu.data error:&error];
        if (error) {
            completion(nil, error);
            return;
        }
    } else {
        data = apdu.data;
    }
    
    UInt8 cla = apdu.cla | 0x04;
    NSMutableData *apduData = [apdu.data mutableCopy];
    [apduData increaseLengthBy:8];
    NSMutableData *macInput = [[[YKFAPDU alloc] initWithCla:cla ins:apdu.ins p1:apdu.p1 p2:apdu.p2 data:apduData type:apdu.type].apduData mutableCopy];
    [macInput setLength:(macInput.length - 8)];
    NSError *error = nil;
    NSData *mac = [self.state macWithData:macInput error:&error];
    if (error) {
        completion(nil, error);
        return;
    }
    NSMutableData *dataAndMac = [data mutableCopy];
    [dataAndMac appendData:mac];
    YKFAPDU *processedAPDU = [[YKFAPDU alloc] initWithCla:cla ins:apdu.ins p1:apdu.p1 p2:apdu.p2 data:dataAndMac type:apdu.type];
    
    NSMutableData *resultData = [NSMutableData new];
    
    [smartCardInterface executeRecursiveCommand:processedAPDU sendRemainingIns:sendRemainingIns timeout:20 data:resultData completion:^(NSData * _Nullable result, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        if (result.length > 0) {
            NSError *unmacError = nil;
            result = [self.state unmacWithData:result sw:0x9000 error:&unmacError];
            if (unmacError) {
                completion(nil, unmacError);
                return;
            }
        }
        
        if (result.length > 0) {
            NSError *decryptError = nil;
            result = [self.state decrypt:result error:&decryptError];
            if (decryptError) {
                completion(nil, decryptError);
                return;
            }
        }
        
        completion(result, nil);
    }];
}


@end
