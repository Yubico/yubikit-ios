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

#ifndef YKFSCPState_h
#define YKFSCPState_h

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

NS_ASSUME_NONNULL_BEGIN

@class YKFSCPSessionKeys;

@interface YKFSCPState : NSObject

@property (nonatomic, strong, readonly) YKFSCPSessionKeys *sessionKeys;
@property (nonatomic, strong) NSMutableData *macChain;
@property (nonatomic, assign) uint32_t encCounter;

- (instancetype)initWithSessionKeys:(YKFSCPSessionKeys *)sessionKeys macChain:(NSData *)macChain;
- (NSData *)encrypt:(NSData *)data error:(NSError **)error;
- (NSData *)decrypt:(NSData *)data error:(NSError **)error;
- (NSData * _Nullable)unpadData:(NSData *)data;
- (NSData *)macWithData:(NSData *)data error:(NSError **)error;
- (NSData *)unmacWithData:(NSData *)data sw:(uint16_t)sw error:(NSError **)error;
- (NSString *)debugDescription;

@end

NS_ASSUME_NONNULL_END

#endif /* YKFSCPState_h */
