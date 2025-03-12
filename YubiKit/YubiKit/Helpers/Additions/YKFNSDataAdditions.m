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

#import <Foundation/Foundation.h>
#import "YKFNSDataAdditions.h"
#import "YKFNSDataAdditions+Private.h"
#import "MF_Base32Additions.h"

#pragma mark - SHA

@implementation NSData(NSData_SHAAdditions)

- (NSData *)ykf_SHA1 {
    UInt8 digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1((const void *)[self bytes], (CC_LONG)[self length], digest);
    return [[NSData alloc] initWithBytes:(const void *)digest length:CC_SHA1_DIGEST_LENGTH];
}

- (NSData *)ykf_SHA256 {
	UInt8 digest[CC_SHA256_DIGEST_LENGTH];
	CC_SHA256((const void *)[self bytes], (CC_LONG)[self length], digest);
	return [[NSData alloc] initWithBytes:(const void *)digest length:CC_SHA256_DIGEST_LENGTH];
}

- (NSData *)ykf_SHA512 {
    UInt8 digest[CC_SHA512_DIGEST_LENGTH];
    CC_SHA512((const void *)[self bytes], (CC_LONG)[self length], digest);
    return [[NSData alloc] initWithBytes:(const void *)digest length:CC_SHA512_DIGEST_LENGTH];
}

@end

#pragma mark - OATH

@implementation NSData(NSData_OATHAdditions)

- (NSData *)ykf_deriveOATHKeyWithSalt:(NSData *)salt {
    if (!salt.length) {
        return nil;
    }
    
    UInt8 keyLength = 16; // use only 16 bytes
    UInt8 key[keyLength];
    CCKeyDerivationPBKDF(kCCPBKDF2, self.bytes, self.length, salt.bytes, salt.length, kCCPRFHmacAlgSHA1, 1000, key, keyLength);
    return [NSData dataWithBytes:key length:keyLength];
}

- (NSData *)ykf_oathHMACWithKey:(NSData *)key {
    if (!key.length) {
        return nil;
    }
    
    UInt8 *keyBytes = (UInt8 *)key.bytes;
    UInt8 *dataBytes = (UInt8 *)self.bytes;
    
    UInt8 result[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, keyBytes, key.length, dataBytes, self.length, result);
    
    return [[NSData alloc] initWithBytes:result length:CC_SHA1_DIGEST_LENGTH];
}

- (NSString *)ykf_parseOATHOTPFromIndex:(NSUInteger)index digits:(UInt8)digits {
    if (index + sizeof(UInt32) > self.length) {
        return nil;
    }
    
    UInt32 otpResponseValue = CFSwapInt32BigToHost(*((UInt32 *)&self.bytes[index]));
    otpResponseValue &= 0x7FFFFFFF; // remove first bit (sign bit)
    
    UInt32 modMask = pow(10, digits); // get last [digits] only
    otpResponseValue = otpResponseValue % modMask;
    
    NSString *otp = nil;
    
    // Format with 0 paddigs up to [digits] number
    if (digits == 6) {
        otp = [NSString stringWithFormat:@"%06d", (unsigned int)otpResponseValue];
    } else if (digits == 7){
        otp = [NSString stringWithFormat:@"%07d", (unsigned int)otpResponseValue];
    } else if (digits == 8){
        otp = [NSString stringWithFormat:@"%08d", (unsigned int)otpResponseValue];
    } else {
        return nil;
    }
    
    return otp;
}

@end

#pragma mark - FIDO2

@implementation NSData (NSDATA_FIDO2Additions)

- (NSData *)ykf_fido2HMACWithKey:(NSData *)key {
    if (!key.length) {
        return nil;
    }
    
    UInt8 *keyBytes = (UInt8 *)key.bytes;
    UInt8 *dataBytes = (UInt8 *)self.bytes;
    
    UInt8 result[CC_SHA256_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA256, keyBytes, key.length, dataBytes, self.length, result);
    
    return [[NSData alloc] initWithBytes:result length:CC_SHA256_DIGEST_LENGTH];
}

- (NSData *)ykf_aes256EncryptedDataWithKey:(NSData *)key {
    return [self ykf_aes256Operation:kCCEncrypt withKey:key];
}

- (NSData *)ykf_aes256DecryptedDataWithKey:(NSData *)key {
    return [self ykf_aes256Operation:kCCDecrypt withKey:key];
}

- (NSData *)ykf_aes256Operation:(CCOperation)operation withKey:(NSData *)key {
    if (!key.length) {
        return nil;
    }
    
    size_t outLength;
    NSMutableData *outData = [NSMutableData dataWithLength:self.length + kCCBlockSizeAES128];
    
    CCCryptorRef ccRef = NULL;
    CCCryptorCreate(operation, kCCAlgorithmAES, 0, key.bytes, kCCKeySizeAES256, NULL, &ccRef);
    if (!ccRef) {
        return nil;
    }
    CCCryptorStatus cryptStatus = CCCryptorUpdate(ccRef, self.bytes, self.length, outData.mutableBytes, outData.length, &outLength);
    CCCryptorRelease(ccRef);
    
    if(cryptStatus == kCCSuccess) {
        outData.length = outLength;
        return outData;
    }
    return nil;
}

- (NSData *)ykf_fido2PaddedPinData {
    if (!self.length) {
        return nil;
    }
    if (self.length == 64) {
        return self;
    }
    if ((self.length > 64) && (self.length % 16 == 0)) {
        return self;
    }
    
    NSMutableData *mutableData = [[NSMutableData alloc] initWithData:self];
    NSUInteger lengthToIncrease = 0;
    if (self.length < 64) {
        lengthToIncrease = 64 - self.length;
    } else {
        lengthToIncrease = 16 - self.length % 16;
    }
    
    if (lengthToIncrease) {
        [mutableData increaseLengthBy:lengthToIncrease];
    }
    
    return [mutableData copy];
}

@end

#pragma mark - PIV

@implementation NSData(NSDATA_PIVAdditions)

- (NSData *)ykf_encryptDataWithAlgorithm:(CCAlgorithm)algorithm key:(NSData *)key {
    return [self ykf_cryptOperation:kCCEncrypt algorithm:algorithm key:key];
}

- (NSData *)ykf_decryptedDataWithAlgorithm:(CCAlgorithm)algorithm key:(NSData *)key {
    return [self ykf_cryptOperation:kCCDecrypt algorithm:algorithm key:key];
}

- (NSData *)ykf_cryptOperation:(CCOperation)operation algorithm:(CCAlgorithm)algorithm key:(NSData *)key {
    if (!key.length) {
        return nil;
    }
    
    int blockSize;
    
    switch (algorithm) {
        case kCCAlgorithm3DES:
            blockSize = kCCBlockSize3DES;
            break;
        case kCCAlgorithmAES:
            blockSize = kCCBlockSizeAES128;
            break;
        default:
            return nil;
            break;
    }

    size_t outLength;
    NSMutableData *outData = [NSMutableData dataWithLength:self.length + blockSize];
    
    CCCryptorRef ccRef = NULL;
    CCCryptorCreate(operation, algorithm, kCCOptionECBMode, key.bytes, key.length, NULL, &ccRef);
    if (!ccRef) {
        return nil;
    }
    CCCryptorStatus cryptStatus = CCCryptorUpdate(ccRef, self.bytes, self.length, outData.mutableBytes, outData.length, &outLength);
    CCCryptorRelease(ccRef);
    
    if(cryptStatus == kCCSuccess) {
        outData.length = outLength;
        return outData;
    }
    return nil;
}

+ (nullable NSData *)ykf_randomDataOfSize:(size_t)sizeInBytes {
    void *buff = malloc(sizeInBytes);
    if (buff == NULL) {
        return nil;
    }
    arc4random_buf(buff, sizeInBytes);

    return [NSData dataWithBytesNoCopy:buff length:sizeInBytes freeWhenDone:YES];
}

- (NSData *)ykf_hkdfExtract:(NSData *)salt {
    return [self ykf_fido2HMACWithKey:salt];
}

-(NSData *)ykf_hkdfExpand:(NSData *)info {
    NSMutableData *data = [info mutableCopy];
    UInt8 zero = 0x01;
    [data appendBytes:&zero length:1];
    return [data ykf_fido2HMACWithKey:self];
}

- (NSData *)ykf_deriveHKDFWithSalt:(NSData *)salt info:(NSData *)info {
    NSData *prk = [self ykf_hkdfExtract:salt];
    return [prk ykf_hkdfExpand:info];
}

- (NSData *)ykf_toLength:(int)length {
    if (self.length == length) {
        return self;
    } else if (self.length > length) {
        return [self subdataWithRange:NSMakeRange(self.length - length, length)];
    } else {
        NSMutableData *paddedData = [NSMutableData data];
        UInt8 padding = 0x00;
        int paddingSize = length - (int)self.length;
        for (int i = 0; i < paddingSize; i++) {
            [paddedData appendBytes:&padding length:1];
        }
        [paddedData appendData:self];
        return paddedData;
    }
}

@end

#pragma mark - AESCMAC

@implementation NSData(NSDATA_AESCMAC)

- (NSData *)ykf_aesCMACWithKey:(NSData *)key {
    NSData *constZero = [NSData dataWithBytes:(UInt8[]){0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00} length:16];
    NSData *constRb = [NSData dataWithBytes:(UInt8[]){0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x87} length:16];
    NSInteger blockSize = 16;
    CCAlgorithm algorithm = kCCAlgorithmAES128;
    NSData *iv = constZero.copy;
    
    NSData *l = [constZero ykf_cryptOperation:kCCEncrypt algorithm:algorithm mode:kCCModeCBC key:key iv:iv];
    NSData *subKey1 = [l ykf_shiftedLeftByOne];
    if (((const uint8_t *)l.bytes)[0] & 0x80) {
        subKey1 = [constRb ykf_xorWithKey:subKey1];
    }
    NSData *subKey2 = [subKey1 ykf_shiftedLeftByOne];
    if (((const uint8_t *)subKey1.bytes)[0] & 0x80) {
        subKey2 = [constRb ykf_xorWithKey:subKey2];
    }
    
    BOOL lastBlockIsComplete = (self.length % blockSize == 0) && (self.length > 0);
    
    NSData *paddedData;
    NSData *lastIv;
    if (lastBlockIsComplete) {
        lastIv = subKey1;
        paddedData = self;
    } else {
        lastIv = subKey2;
        paddedData = [self ykf_bitPadded];
    }
    NSData *messageSkippingLastBlock = [paddedData subdataWithRange:NSMakeRange(0, paddedData.length - blockSize)];
    NSData *lastBlock = [paddedData subdataWithRange:NSMakeRange(messageSkippingLastBlock.length, paddedData.length - messageSkippingLastBlock.length)];
    if (messageSkippingLastBlock.length != 0) {
        // CBC encrypt the message (minus the last block) with a zero IV, and keep only the last block:
        NSData *encryptedData = [messageSkippingLastBlock ykf_cryptOperation:kCCEncrypt algorithm:algorithm mode:kCCModeCBC key:key iv:iv];
        NSData *encryptedBlock = [encryptedData subdataWithRange:NSMakeRange(messageSkippingLastBlock.length - blockSize, blockSize)];
        lastIv = [lastIv ykf_xorWithKey:encryptedBlock];
    }
    
    return [lastBlock ykf_cryptOperation:kCCEncrypt algorithm:algorithm mode:kCCModeCBC key:key iv:lastIv];
}

- (NSData *)ykf_cryptOperation:(CCOperation)operation algorithm:(CCAlgorithm)algorithm mode:(CCMode)mode key:(NSData *)key iv:(NSData *)iv {
    if (!key.length) { return nil; }
    
    int blockSize;
    switch (algorithm) {
        case kCCAlgorithm3DES:
            blockSize = kCCBlockSize3DES;
            break;
        case kCCAlgorithmAES:
            blockSize = kCCBlockSizeAES128;
            break;
        default:
            return nil;
            break;
    }
    
    size_t outLength = 0;
    NSMutableData *buffer = [NSMutableData dataWithLength:self.length + blockSize];
    
    CCCryptorRef cryptorRef = NULL;
    CCCryptorCreateWithMode(operation,
                            mode,
                            algorithm,
                            ccNoPadding,
                            iv.bytes,
                            key.bytes,
                            key.length,
                            nil,
                            0,
                            0,
                            0,
                            &cryptorRef
                            );
    
    CCCryptorUpdate(cryptorRef,
                    self.bytes,
                    self.length,
                    buffer.mutableBytes,
                    buffer.length,
                    &outLength);
    
    CCCryptorStatus cryptorStatus = CCCryptorCreate(operation, algorithm, kCCOptionECBMode, key.bytes, key.length, NULL, &cryptorRef);
    CCCryptorRelease(cryptorRef);
    
    if(cryptorStatus == kCCSuccess) {
        buffer.length = outLength;
        return buffer;
    }
    return nil;
}

- (NSData*)ykf_shiftedLeftByOne {
    NSUInteger length = self.length;
    if (length == 0) {
        return [NSData data];
    }
    
    NSMutableData *shiftedData = [NSMutableData dataWithLength:length];
    uint8_t *shiftedBytes = (uint8_t *)shiftedData.mutableBytes;
    const uint8_t *originalBytes = (const uint8_t *)self.bytes;
    
    NSUInteger lastIndex = length - 1;
    for (NSUInteger i = 0; i < lastIndex; i++) {
        shiftedBytes[i] = originalBytes[i] << 1;
        if ((originalBytes[i + 1] & 0x80) != 0) {
            shiftedBytes[i] += 0x01;
        }
    }
    shiftedBytes[lastIndex] = originalBytes[lastIndex] << 1;
    
    return [NSData dataWithData:shiftedData];
}

- (NSData*)ykf_xorWithKey:(NSData *)key {
    if (self.length != key.length) { abort(); }
    
    NSMutableData *result = [NSMutableData dataWithLength:self.length];
    
    const uint8_t *selfBytes = (const uint8_t *)self.bytes;
    const uint8_t *keyBytes = (const uint8_t *)key.bytes;
    uint8_t *resultBytes = (uint8_t *)result.mutableBytes;
    
    for (NSUInteger i = 0; i < self.length; i++) {
        resultBytes[i] = selfBytes[i] ^ keyBytes[i];
    }
    
    return [NSData dataWithData:result];
}

- (NSData *)ykf_bitPadded {
    NSUInteger msgLength = self.length;
    NSUInteger blockSize = 16;
    
    NSMutableData *paddedData = [self mutableCopy];
    uint8_t paddingByte = 0x80;
    [paddedData appendBytes:&paddingByte length:1];
    NSUInteger paddingLength;
    if (msgLength % blockSize < blockSize) {
        paddingLength = blockSize - 1 - (msgLength % blockSize);
    } else {
        paddingLength = (blockSize * 2) - 1 - (msgLength % blockSize);
    }
    [paddedData increaseLengthBy:paddingLength];

    return [NSData dataWithData:paddedData];
}

@end

#pragma mark - Marshalling

@implementation NSData(NSData_Marshalling)

- (NSUInteger)ykf_getBigEndianIntegerInRange:(NSRange)range {
    NSInteger numberOfBytes = range.length;
    if (numberOfBytes>sizeof(NSUInteger)) {
        numberOfBytes = sizeof(NSUInteger);
    }
    Byte buffer[numberOfBytes];
    [self getBytes:buffer range:NSMakeRange(range.location, numberOfBytes)];
    NSUInteger value = 0;
    for(NSInteger i = 0; i < numberOfBytes; ++i){
        value = (value<<8) | buffer[i];
    }
    return value;
}

@end

#pragma mark - WebSafe Base64

@implementation NSData(NSData_WebSafeBase64)

- (instancetype)ykf_initWithWebsafeBase64EncodedString:(NSString *)websafeBase64EncodedData dataLength:(NSUInteger)dataLen {
    if (!websafeBase64EncodedData) {
        return nil;
    }
    NSMutableString *base64EncodedString = [[NSMutableString alloc] initWithString:websafeBase64EncodedData];
    [base64EncodedString replaceOccurrencesOfString:@"-" withString:@"+" options:0 range:NSMakeRange(0, [base64EncodedString length])];
    [base64EncodedString replaceOccurrencesOfString:@"_" withString:@"/" options:0 range:NSMakeRange(0, [base64EncodedString length])];
    if ((dataLen % 3) == 1){
        [base64EncodedString appendString:@"=="];
    }
    else if ((dataLen % 3) == 2) {
        [base64EncodedString appendString:@"="];
    }
    return [self initWithBase64EncodedString:base64EncodedString options:0];
}

- (NSString *)ykf_websafeBase64EncodedString {
    NSMutableString *base64 = [[NSMutableString alloc] initWithString:[self base64EncodedStringWithOptions:0]];
    [base64 replaceOccurrencesOfString:@"+" withString:@"-" options:0 range:NSMakeRange(0, [base64 length])];
    [base64 replaceOccurrencesOfString:@"/" withString:@"_" options:0 range:NSMakeRange(0, [base64 length])];
    [base64 replaceOccurrencesOfString:@"=" withString:@"" options:0 range:NSMakeRange(0, [base64 length])];
    
    return [NSString stringWithString:base64];
}

@end

#pragma mark - Size Check

@implementation NSData(NSDATA_SizeCheckAdditions)

- (BOOL)ykf_containsIndex:(NSUInteger) index {
    return index < self.length;
}

- (BOOL)ykf_containsRange:(NSRange) range {
    return range.location + range.length <= self.length;
}

@end

#pragma mark - Base32

@implementation NSData(NSData_Base32Additions)

+ (NSData *)ykf_dataWithBase32String:(NSString *)base32String {
    NSRange range = NSMakeRange(0, [base32String length]);
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: @"[A-Za-z2-7=]*" options: 0 error: &error];
    NSRange foundRange = [regex rangeOfFirstMatchInString: base32String options: 0 range: range];
    if (!NSEqualRanges(range, foundRange)) return nil;
    
    return [self dataWithBase32String: base32String];
}

- (NSString *)ykf_base32String {
    return [self base32String];
}

@end

#pragma mark - HEX string conversion

@implementation NSData (NSData_HexConversion)

- (NSString *)ykf_hexadecimalString
{
    /* Returns hexadecimal string of NSData. Empty string if data is empty. */
    const unsigned char *dataBuffer = (const unsigned char *)[self bytes];
    if (!dataBuffer) {
        return [NSString string];
    }

    NSUInteger          dataLength  = [self length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendFormat:@"%02x", (unsigned int)dataBuffer[i]];
    }

    return [NSString stringWithString:hexString];
}

@end

#pragma mark - INT conversion

@implementation NSData (NSData_IntConversion)

- (NSUInteger)ykf_integerValue
{
    UInt8 *dataBytes = (UInt8 *)self.bytes;
    if (!dataBytes) {
        return 0;
    }
    
    NSUInteger value = 0;
    NSUInteger dataLength  = [self length];
    for (int i = 0; i < dataLength; ++i) {
        value <<= 8;
        value += dataBytes[i];
    }

    return value;
}

@end
