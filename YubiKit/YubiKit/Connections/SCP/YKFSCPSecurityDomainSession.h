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

#ifndef YKFSCPSecurityDomainSession_h
#define YKFSCPSecurityDomainSession_h

#import <Foundation/Foundation.h>
#import "YKFSession.h"
#import "YKFVersion.h"

NS_ASSUME_NONNULL_BEGIN

@class YKFSCPKeyRef;

typedef void (^YKFSecurityDomainSessionDataCompletionBlock)
    (NSData* _Nullable data, NSError* _Nullable error);

typedef void (^YKFSecurityDomainSessionCertificateBundleCompletionBlock)
    (NSArray* _Nullable certificates, NSError* _Nullable error);

@interface YKFSecurityDomainSession: YKFSession // <YKFVersionProtocol>

- (void)getDataWithTag:(UInt16)tag data:(NSData * _Nullable)data  completion:(YKFSecurityDomainSessionDataCompletionBlock)completion;

- (void)getCertificateBundleWithKeyRef:(YKFSCPKeyRef *)keyRef completion:(YKFSecurityDomainSessionCertificateBundleCompletionBlock)completion;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

#endif
