// Copyright 2018-2020 Yubico AB
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
#import "YKFSmartCardInterface.h"
#import "YKFKeyConnectionControllerProtocol.h"
#import "YKFAssert.h"
#import "YKFNSDataAdditions.h"
#import "YKFNSDataAdditions+Private.h"
#import "YKFKeyAPDUError.h"


#import "YKFAccessoryConnectionController.h"
#import "YKFKeySessionError.h"
#import "YKFBlockMacros.h"
#import "YKFAssert.h"
#import "YKFLogger.h"
#import "YKFKeyAPDUError.h"

#import "YKFAPDU+Private.h"
#import "YKFKeySessionError+Private.h"

#import "YKFNSDataAdditions+Private.h"
#import "YKFOATHSendRemainingAPDU.h"
#import "YKFSelectApplicationAPDU.h"

@interface YKFSmartCardInterface()

@property (nonatomic, readwrite) id<YKFKeyConnectionControllerProtocol> connectionController;

- (NSData *)dataFromKeyResponse:(NSData *)response;
- (UInt16)statusCodeFromKeyResponse:(NSData *)response;

@end

@implementation YKFSmartCardInterface

-(instancetype)initWithConnectionController:(id<YKFKeyConnectionControllerProtocol>)connectionController {
    self = [super init];
    if (self) {
        self.connectionController = connectionController;
    }
    return self;
}

- (void)selectApplication:(YKFSelectApplicationAPDU *)apdu completion:(YKFKeySmartCardInterfaceResponseBlock)completion {
    [self.connectionController execute:apdu completion:^(NSData *response, NSError *error, NSTimeInterval executionTime) {
        if (error) {
            completion(nil, error);
            return;
        }
        UInt16 statusCode = [self statusCodeFromKeyResponse:response];
        NSData *data = [self dataFromKeyResponse:response];
        if (statusCode == YKFKeyAPDUErrorCodeNoError) {
            completion(data, nil);
        } else if (statusCode == YKFKeyAPDUErrorCodeMissingFile || statusCode == YKFKeyAPDUErrorCodeInsNotSupported) {
            NSError *error = [YKFKeySessionError errorWithCode:YKFKeySessionErrorMissingApplicationCode];
            completion(nil, error);
        } else {
            NSAssert(TRUE, @"The key returned an unexpected SW when selecting application");
            NSError *error = [YKFKeySessionError errorWithCode:YKFKeySessionErrorUnexpectedStatusCode];
            completion(nil, error);
        }
    }];
}

- (void)executeCommand:(YKFAPDU *)apdu sendRemainingIns:(YKFSmartCardInterfaceSendRemainingIns)sendRemainingIns  configuration:(YKFKeyCommandConfiguration *)configuration data:(NSMutableData *)data completion:(YKFKeySmartCardInterfaceResponseBlock)completion {
    [self.connectionController execute:apdu
                         configuration:configuration
                            completion:^(NSData *response, NSError *error, NSTimeInterval executionTime) {
        if (error) {
            completion(nil, error);
            return;
        }

        [data appendData:[self dataFromKeyResponse:response]];
        UInt16 statusCode = [self statusCodeFromKeyResponse:response];
        
        if (statusCode >> 8 == YKFKeyAPDUErrorCodeMoreData) {
            YKFLogInfo(@"Key has more data to send. Requesting for remaining data...");
            UInt16 ins;
            switch (sendRemainingIns) {
                case YKFSmartCardInterfaceSendRemainingInsNormal:
                    ins = 0xC0;
                    break;
                case YKFSmartCardInterfaceSendRemainingInsOATH:
                    ins = 0xA5;
                    break;
            }
            YKFAPDU *sendRemainingApdu = [[YKFAPDU alloc] initWithData:[NSData dataWithBytes:(unsigned char[]){0x00, ins, 0x00, 0x00} length:4]];
            // Queue a new request recursively
            [self executeCommand:sendRemainingApdu sendRemainingIns:sendRemainingIns configuration:configuration data:data completion:completion];
            return;
        } else if (statusCode == 0x9000) {
            completion(data, nil);
            return;
        } else {
            YKFKeySessionError *error = [YKFKeySessionError errorWithCode:statusCode];
            completion(nil, error);
        }
    }];
}

- (void)executeCommand:(YKFAPDU *)apdu completion:(YKFKeySmartCardInterfaceResponseBlock)completion {
    [self executeCommand:apdu sendRemainingIns:YKFSmartCardInterfaceSendRemainingInsNormal configuration:[YKFKeyCommandConfiguration defaultCommandCofiguration] completion:completion];
}

- (void)executeCommand:(YKFAPDU *)apdu sendRemainingIns:(YKFSmartCardInterfaceSendRemainingIns)sendRemainingIns completion:(YKFKeySmartCardInterfaceResponseBlock)completion {
    [self executeCommand:apdu sendRemainingIns:sendRemainingIns  configuration:[YKFKeyCommandConfiguration defaultCommandCofiguration] completion:completion];
}

- (void)executeCommand:(YKFAPDU *)apdu sendRemainingIns:(YKFSmartCardInterfaceSendRemainingIns)sendRemainingIns configuration:(YKFKeyCommandConfiguration *)configuration completion:(YKFKeySmartCardInterfaceResponseBlock)completion {
    YKFParameterAssertReturn(apdu);
    YKFParameterAssertReturn(completion);
    NSMutableData *data = [NSMutableData new];
    [self executeCommand:apdu sendRemainingIns:sendRemainingIns configuration:configuration data:data completion:completion];
}

- (void)executeAfterCurrentCommands:(YKFKeySmartCardInterfaceExecutionBlock)block delay:(NSTimeInterval)delay {
    [self.connectionController dispatchOnSequentialQueue:block delay:delay];
}

- (void)executeAfterCurrentCommands:(YKFKeySmartCardInterfaceExecutionBlock)block {
    [self executeAfterCurrentCommands:block delay:0];
}

#pragma mark - Helpers

- (NSData *)dataFromKeyResponse:(NSData *)response {
    YKFParameterAssertReturnValue(response, [NSData data]);
    YKFAssertReturnValue(response.length >= 2, @"Key response data is too short.", [NSData data]);
    
    if (response.length == 2) {
        return [NSData data];
    } else {
        NSRange range = {0, response.length - 2};
        return [response subdataWithRange:range];
    }
}

- (UInt16)statusCodeFromKeyResponse:(NSData *)response {
    YKFParameterAssertReturnValue(response, YKFKeyAPDUErrorCodeWrongLength);
    YKFAssertReturnValue(response.length >= 2, @"Key response data is too short.", YKFKeyAPDUErrorCodeWrongLength);
    
    return [response ykf_getBigEndianIntegerInRange:NSMakeRange([response length] - 2, 2)];
}

@end
