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

#import "YKFKeyService.h"
#import "YKFKeyService+Private.h"
#import "YKFKeyConnectionController.h"
#import "YKFNSDataAdditions.h"
#import "YKFNSDataAdditions+Private.h"
#import "YKFKeyAPDUError.h"
#import "YKFAssert.h"

@implementation YKFKeyService

#pragma mark - Key Response

- (NSData *)dataFromKeyResponse:(NSData *)response {
    YKFParameterAssertReturnValue(response, [NSData data]);
    YKFAssertReturnValue(response.length >= 3, @"Key response data is too short.", [NSData data]);
    
    UInt8 *bytes = (UInt8 *)response.bytes;
    YKFParameterAssertReturnValue(bytes[0] == 0x00 || bytes[0] == 0x01, [NSData data]);
    
    if (bytes[0] == 0x00) {
        // Remove the first byte (the YLP key protocol header) and the last 2 bytes (the SW)
        NSRange range = {1, response.length - 3};
        return [response subdataWithRange:range];
    }
    else if (bytes[0] == 0x01) {        
        // Remove the first byte (the YLP key protocol header), the WTX and the last 2 bytes (the SW)
        NSRange range = {4, response.length - 6};
        return [response subdataWithRange:range];
    }
    
    return [NSData data];
}

- (NSData *)dataAndStatusFromKeyResponse:(NSData *)response {
    YKFParameterAssertReturnValue(response, [NSData data]);
    YKFAssertReturnValue(response.length >= 3, @"Key response data is too short.", [NSData data]);
    
    // Remove the first byte (the YLP key protocol header)
    NSRange range = {1, response.length - 1};
    return [response subdataWithRange:range];
}

#pragma mark - Status Code

- (UInt16)statusCodeFromKeyResponse:(NSData *)response {    
    YKFParameterAssertReturnValue(response, YKFKeyAPDUErrorCodeWrongLength);
    YKFAssertReturnValue(response.length >= 3, @"Key response data is too short.", YKFKeyAPDUErrorCodeWrongLength);
    
    return [response ykf_getBigEndianIntegerInRange:NSMakeRange([response length] - 2, 2)];
}

- (UInt8)shortStatusCodeFromStatusCode:(UInt16)statusCode {
    return (UInt8)(statusCode >> 8);
}

#pragma mark - YKFKeyServiceDelegate

- (void)keyService:(YKFKeyService *)service willExecuteRequest:(YKFKeyRequest *)request {
    // Does nothing: override this in the service subclasses when necessary.
}

@end
