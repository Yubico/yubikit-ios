// Copyright 2018-2021 Yubico AB
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

#import <Foundation/Foundation.h>
#import "YKFPIVPadding+Private.h"

@implementation YKFPIVPadding

+ (NSData *)padData:(NSData *)data keyType:(YKFPIVKeyType)keyType algorithm:(SecKeyAlgorithm)algorithm error:(NSError **)error {
    if (keyType == YKFPIVKeyTypeRSA2048 || keyType == YKFPIVKeyTypeRSA1024) {
        NSNumber *size = [NSNumber numberWithInt:YKFPIVSizeFromKeyType(keyType) * 8];
        CFDictionaryRef attributes = (__bridge CFDictionaryRef) (@{(id)kSecAttrKeyType: (id)kSecAttrKeyTypeRSA,
                                                                   (id)kSecAttrKeySizeInBits: size});
        
        SecKeyRef publicKey;
        SecKeyRef privateKey;
        SecKeyGeneratePair(attributes, &publicKey, &privateKey);
        CFErrorRef cfErrorRef = nil;
        CFDataRef cfDataRef = (__bridge CFDataRef)data;
        CFDataRef cfEncryptedDataRef = SecKeyCreateEncryptedData(publicKey, algorithm, cfDataRef, &cfErrorRef);
        CFRelease(publicKey);
        if (cfErrorRef) {
            NSError *encryptError = (__bridge NSError *)cfErrorRef;
            *error = encryptError;
            return nil;
        }
        CFDataRef cfDecryptedDataRef = SecKeyCreateDecryptedData(privateKey, kSecKeyAlgorithmRSAEncryptionRaw, cfEncryptedDataRef, &cfErrorRef);
        CFRelease(privateKey);
        if (cfErrorRef) {
            NSError *decryptError = (__bridge NSError *)cfErrorRef;
            *error = decryptError;
            return nil;
        }
        NSData *decrypted = (__bridge NSData*)cfDecryptedDataRef;
        return decrypted;
    } else if (keyType == YKFPIVKeyTypeECCP256 || keyType == YKFPIVKeyTypeECCP384) {
        *error = [[NSError alloc] initWithDomain:@"com.yubico.piv" code:1 userInfo:@{NSLocalizedDescriptionKey: @"EC padding not implemented."}];
        return nil;
    } else {
        return nil;
    }
}

+ (NSData *)unpadRSAData:(NSData *)data algorithm:(SecKeyAlgorithm)algorithm error:(NSError **)error {
    NSNumber *size;
    switch (data.length) {
        case 1024 / 8:
            size = @1024;
            break;
        case 2048 / 8:
            size = @2048;
            break;
        default:
            *error = [[NSError alloc] initWithDomain:@"com.yubico.piv" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Failed to unpad RSA data - input buffer bad size."}];
            return nil;
    }
    CFDictionaryRef attributes = (__bridge CFDictionaryRef) @{(id)kSecAttrKeyType: (id)kSecAttrKeyTypeRSA,
                                                              (id)kSecAttrKeySizeInBits: size};
    SecKeyRef publicKey;
    SecKeyRef privateKey;
    SecKeyGeneratePair(attributes, &publicKey, &privateKey);
    CFErrorRef cfErrorRef = nil;
    CFDataRef cfDataRef = (__bridge CFDataRef)data;
    CFDataRef cfEncryptedDataRef = SecKeyCreateEncryptedData(publicKey, kSecKeyAlgorithmRSAEncryptionRaw, cfDataRef, &cfErrorRef);
    CFRelease(publicKey);
    if (cfErrorRef) {
        NSError *encryptError = (__bridge NSError *)cfErrorRef;
        *error = encryptError;
        return nil;
    }
    CFDataRef cfDecryptedDataRef = SecKeyCreateDecryptedData(privateKey, algorithm, cfEncryptedDataRef, &cfErrorRef);
    CFRelease(privateKey);
    if (cfErrorRef) {
        NSError *decryptError = (__bridge NSError *)cfErrorRef;
        *error = decryptError;
        return nil;
    }
    NSData *decrypted = (__bridge NSData*)cfDecryptedDataRef;
    return decrypted;
}

@end
