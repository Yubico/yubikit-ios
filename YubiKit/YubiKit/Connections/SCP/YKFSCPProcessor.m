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

#import "YKFNSDataAdditions.h"
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
#import "YKFTLVRecord.h"

@interface YKFSCPProcessor ()
@property (nonatomic, strong) YKFSCPState *state;
@end

typedef NS_ENUM(uint8_t, YKFSCPKid) {
    YKFSCPKidScp03  = 0x01,
    YKFSCPKidScp11a = 0x11,
    YKFSCPKidScp11b = 0x13,
    YKFSCPKidScp11c = 0x15,
};

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
    
    if ([scpKeyParams isKindOfClass:[YKFSCP11KeyParams class]]) {
        YKFSCP11KeyParams *scp11Params = (YKFSCP11KeyParams *)scpKeyParams;
        
        uint8_t kidValue = scpKeyParams.keyRef.kid;
        YKFSCPKid kid = (YKFSCPKid)kidValue;
        
        uint8_t params;
        
        if (kid == YKFSCPKidScp11a) {
            params = 0b01;
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"SCP11a not implemented" userInfo:nil];
        } else if (kid == YKFSCPKidScp11b) {
            params = 0b00;
        } else if (kid == YKFSCPKidScp11c) {
            params = 0b11;
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"SCP11c not implemented" userInfo:nil];
        } else {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Unknown SCP11 version" userInfo:nil];
        }
        
        NSData *keyUsage = [NSData dataWithBytes:(uint8_t[]){0x3c} length:1];
        NSData *keyType = [NSData dataWithBytes:(uint8_t[]){0x88} length:1];
        NSData *keyLen = [NSData dataWithBytes:(uint8_t[]){16} length:1];
        
        SecKeyRef pkSdEcka = scp11Params.pkSdEcka;
        CFRetain(pkSdEcka);
        
        NSDictionary *attributes = @{(__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeEC,
                                     (__bridge id)kSecAttrKeySizeInBits: @256};
        
        CFErrorRef error = NULL;
        SecKeyRef eskOceEcka = SecKeyCreateRandomKey((__bridge CFDictionaryRef)attributes, &error);
        if (!eskOceEcka) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[(__bridge NSError *)error localizedDescription] userInfo:nil];
        }
        
        SecKeyRef epkOceEcka = SecKeyCopyPublicKey(eskOceEcka);
        if (!epkOceEcka) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[(__bridge NSError *)error localizedDescription] userInfo:nil];
        }
        
        CFDataRef externalRepresentation = SecKeyCopyExternalRepresentation(epkOceEcka, &error);
        if (!externalRepresentation) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[(__bridge NSError *)error localizedDescription] userInfo:nil];
        }
        NSData *epkOceEckaData = [(__bridge NSData *)externalRepresentation subdataWithRange:NSMakeRange(0, 1 + 2 * 32)];
        
        // GPC v2.3 Amendment F (SCP11) v1.4 §7.6.2.3
        NSMutableData *data = [[[YKFTLVRecord alloc] initWithTag:0xa6 records: @[
            [[YKFTLVRecord alloc] initWithTag:0x90 value:[NSData dataWithBytes:(uint8_t[]){0x11, params} length:2]],
            [[YKFTLVRecord alloc] initWithTag:0x95 value:keyUsage],
            [[YKFTLVRecord alloc] initWithTag:0x80 value:keyType],
            [[YKFTLVRecord alloc] initWithTag:0x81 value:keyLen],
        ]].data mutableCopy];
        [data appendData:[[YKFTLVRecord alloc] initWithTag:0x5f49 value:epkOceEckaData].data];
        
        SecKeyRef skOceEcka = scp11Params.skOceEcka ?: eskOceEcka;
        uint8_t ins = kid  == YKFSCPKidScp11b ? 0x88 : 0x82;
        
        YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0x80 ins:ins p1:scpKeyParams.keyRef.kvn p2:scpKeyParams.keyRef.kid data:data type:YKFAPDUTypeExtended];
        [smartCardInterface executeCommand:apdu sendRemainingIns:sendRemainingIns completion:^(NSData * _Nullable result, NSError * _Nullable error) {
            if (!result) {
                completion(nil, error);
                return;
            }
            NSArray<YKFTLVRecord *> *tlvs = [YKFTLVRecord sequenceOfRecordsFromData:result];
            if (tlvs.count != 2 || [tlvs[0] tag] != 0x5f49 || [tlvs[1] tag] != 0x86) {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Invalid response TLVs" userInfo:nil];
            }
            
            NSData *epkSdEckaEncodedPoint = tlvs[0].value;
            NSData *receipt = tlvs[1].value;
            NSMutableData *keyAgreementData = [data mutableCopy];
            [keyAgreementData appendData:tlvs[0].data];
            NSMutableData *sharedInfo = [keyUsage mutableCopy];
            [sharedInfo appendData:keyType];
            [sharedInfo appendData:keyLen];
            
            NSDictionary *pkAttributes = @{(__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeEC,
                                           (__bridge id)kSecAttrKeyClass: (__bridge id)kSecAttrKeyClassPublic};
            CFErrorRef cfError = NULL;

            SecKeyRef epkSdEcka = SecKeyCreateWithData((__bridge CFDataRef)epkSdEckaEncodedPoint, (__bridge CFDictionaryRef)pkAttributes, &cfError);
            if (!epkSdEcka) {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[(__bridge NSError *)cfError localizedDescription] userInfo:nil];
            }
            
            NSData *keyAgreement1 = (__bridge_transfer NSData *)SecKeyCopyKeyExchangeResult(eskOceEcka, kSecKeyAlgorithmECDHKeyExchangeStandard, epkSdEcka, (__bridge CFDictionaryRef)@{}, nil);
            NSData *keyAgreement2 = (__bridge_transfer NSData *)SecKeyCopyKeyExchangeResult(skOceEcka, kSecKeyAlgorithmECDHKeyExchangeStandard, pkSdEcka, (__bridge CFDictionaryRef)@{}, nil);
            CFRelease(pkSdEcka);
            
            NSMutableData *keyMaterial = [keyAgreement1 mutableCopy];
            [keyMaterial appendData:keyAgreement2];
            
            NSMutableArray *keys = [NSMutableArray array];
            for (uint32_t counter = 1; counter <= 4; counter++) {
                NSMutableData *dataToHash = [keyMaterial mutableCopy];
                uint32_t bigEndianCounter = CFSwapInt32HostToBig(counter);
                NSData *counterData = [NSData dataWithBytes:&bigEndianCounter length:sizeof(bigEndianCounter)];
                [dataToHash appendData:counterData];
                [dataToHash appendData:sharedInfo];
                NSData *digest = [dataToHash ykf_SHA256];
                [keys addObject:[digest subdataWithRange:NSMakeRange(0, 16)]];
                [keys addObject:[digest subdataWithRange:NSMakeRange(16, digest.length - 16)]];
            }
            
            NSData *genReceipt = [keyAgreementData ykf_aesCMACWithKey:keys[0]];
            if (![genReceipt ykf_constantTimeCompareWithData:receipt]) {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"MAC verification failed" userInfo:nil];
            }
            YKFSCPSessionKeys *sessionKeys = [[YKFSCPSessionKeys alloc] initWithSenc:keys[1] smac:keys[2] srmac:keys[3] dek:keys[4]];
            YKFSCPState *state = [[YKFSCPState alloc] initWithSessionKeys:sessionKeys macChain:receipt];
            
            YKFSCPProcessor *processor = [[YKFSCPProcessor alloc] initWithState:state];
            completion(processor, nil);
            
            NSLog(@"✅ done configuring SCP11");
        }];
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
    NSMutableData *macData = [data mutableCopy];
    [macData increaseLengthBy:8];
    NSMutableData *macInput = [[[YKFAPDU alloc] initWithCla:cla ins:apdu.ins p1:apdu.p1 p2:apdu.p2 data:macData type:apdu.type].apduData mutableCopy];
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
