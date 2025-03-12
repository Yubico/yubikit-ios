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

#ifndef YKFSCPProcessor_h
#define YKFSCPProcessor_h

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>
#import "YKFSmartCardInterface.h"
#import "YKFSCPKeyParamsProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class YKFAPDU, YKFSCPKeyParamsProtocol, YKFSCPState;

@interface YKFSCPProcessor : NSObject

typedef void (^YKFSCPProcessorCompletionBlock)(YKFSCPProcessor *_Nullable, NSError* _Nullable);

+ (void)processorWithSCPKeyParams:(id<YKFSCPKeyParamsProtocol> _Nonnull)scpKeyParams
                 sendRemainingIns:(YKFSmartCardInterfaceSendRemainingIns)sendRemainingIns
          usingSmartCardInterface:(YKFSmartCardInterface *)smartCardInterface
                       completion:(YKFSCPProcessorCompletionBlock _Nonnull)completion;

- (void)executeCommand:(YKFAPDU *)apdu
      sendRemainingIns:(YKFSmartCardInterfaceSendRemainingIns)sendRemainingIns
               encrypt:(BOOL)encrypt
usingSmartCardInterface:(YKFSmartCardInterface *)smartCardInterface
            completion:(YKFSmartCardInterfaceResponseBlock)completion;

- (instancetype)initWithState:(YKFSCPState *)state;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

#endif /* YKFSCPProcessor_h */
