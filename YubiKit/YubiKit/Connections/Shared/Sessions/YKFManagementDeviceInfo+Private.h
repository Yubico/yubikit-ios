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

#ifndef YKFManagementDeviceInfo_Private_h
#define YKFManagementDeviceInfo_Private_h

#import "YKFManagementDeviceInfo.h"

static const NSUInteger YKFManagementTagUSBSupported = 0x01;
static const NSUInteger YKFManagementTagSerialNumber = 0x02;
static const NSUInteger YKFManagementTagUSBEnabled = 0x03;
static const NSUInteger YKFManagementTagFormfactor = 0x04;
static const NSUInteger YKFManagementTagFirmwareVersion = 0x05;
static const NSUInteger YKFManagementTagAutoEjectTimeout = 0x06;
static const NSUInteger YKFManagementTagChallengeResponseTimeout = 0x07;
static const NSUInteger YKFManagementTagDeviceFlags = 0x08;
static const NSUInteger YKFManagementTagNFCSupported = 0x0d;
static const NSUInteger YKFManagementTagNFCEnabled = 0x0e;
static const NSUInteger YKFManagementTagConfigLocked = 0x0a;
static const NSUInteger YKFManagementTagUnlock = 0x0b;
static const NSUInteger YKFManagementTagPartNumber = 0x13;
static const NSUInteger YKFManagementTagFIPSCapable = 0x14;
static const NSUInteger YKFManagementTagFIPSApproved = 0x15;
static const NSUInteger YKFManagementTagPINComplexity = 0x16;
static const NSUInteger YKFManagementTagNFCRestricted = 0x17;
static const NSUInteger YKFManagementTagResetBlocked = 0x18;
static const NSUInteger YKFManagementTagFPSVersion = 0x20;
static const NSUInteger YKFManagementTagSTMVersion = 0x21;

NS_ASSUME_NONNULL_BEGIN

@class YKFTLVRecord;
@interface YKFManagementDeviceInfo()

- (nullable instancetype)initWithTLVRecords:(NSMutableArray<YKFTLVRecord*> *)records defaultVersion:(YKFVersion *)defaultVersion NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

#endif /* YKFManagementDeviceInfo_Private_h */
