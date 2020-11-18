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

#import "YKFKeyRawCommandSession.h"
#import "YKFKeyRawCommandSession+Private.h"
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

@interface YKFKeyRawCommandSession()

@property (nonatomic) id<YKFKeyConnectionControllerProtocol> connectionController;

@end

@implementation YKFKeyRawCommandSession

- (instancetype)initWithConnectionController:(id<YKFKeyConnectionControllerProtocol>)connectionController {
    YKFAssertAbortInit(connectionController);
    
    self = [super init];
    if (self) {
        self.connectionController = connectionController;
    }
    return self;
}

- (void)clearSessionState {}

#pragma mark - Command Execution

- (void)executeCommand:(YKFAPDU *)apdu sendRemainingIns:(YKFRawCommandSessionSendRemainingIns)sendRemainingIns  configuration:(YKFKeyCommandConfiguration *)configuration data:(NSMutableData *)data completion:(YKFKeyRawCommandSessionResponseBlock)completion {
    [self.connectionController execute:apdu
                         configuration:configuration
                            completion:^(NSData *response, NSError * error, NSTimeInterval executionTime) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        [data appendData:[YKFKeySession dataFromKeyResponse: response]];
        UInt16 statusCode = [YKFKeySession statusCodeFromKeyResponse: response];
        
        if (statusCode >> 8 == YKFKeyAPDUErrorCodeMoreData) {
            YKFLogInfo(@"Key has more data to send. Requesting for remaining data...");
            UInt16 ins;
            switch (sendRemainingIns) {
                case YKFRawCommandSessionSendRemainingInsNormal:
                    ins = 0xC0;
                    break;
                case YKFRawCommandSessionSendRemainingInsOATH:
                    ins = 0xA5;
                    break;
            }
            YKFAPDU *sendRemainingApdu = [[YKFAPDU alloc] initWithData:[NSData dataWithBytes:(UInt8[]){0x00, ins, 0x00, 0x00} length:4]];
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

- (void)executeCommand:(YKFAPDU *)apdu sendRemainingIns:(YKFRawCommandSessionSendRemainingIns)sendRemainingIns configuration:(YKFKeyCommandConfiguration *)configuration completion:(YKFKeyRawCommandSessionResponseBlock)completion {
    YKFParameterAssertReturn(apdu);
    YKFParameterAssertReturn(completion);
    NSMutableData *data = [NSMutableData new];
    [self executeCommand:apdu sendRemainingIns:sendRemainingIns configuration:configuration data:data completion:completion];
}

- (void)executeCommand:(YKFAPDU *)apdu sendRemainingIns:(YKFRawCommandSessionSendRemainingIns)sendRemainingIns completion:(YKFKeyRawCommandSessionResponseBlock)completion {
    [self executeCommand:apdu sendRemainingIns:sendRemainingIns  configuration:[YKFKeyCommandConfiguration defaultCommandCofiguration] completion:completion];
}

- (void)executeCommand:(YKFAPDU *)apdu completion:(YKFKeyRawCommandSessionResponseBlock)completion {
    [self executeCommand:apdu sendRemainingIns:YKFRawCommandSessionSendRemainingInsNormal configuration:[YKFKeyCommandConfiguration defaultCommandCofiguration] completion:completion];
}

@end
