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

#ifndef YKFManagementInterfaceConfiguration_Private_h
#define YKFManagementInterfaceConfiguration_Private_h

#import "YKFManagementInterfaceConfiguration.h"

@class YKFManagementDeviceInfo, YKFTLVRecord;

@interface YKFManagementInterfaceConfiguration()

@property (nonatomic, readonly) BOOL usbMaskChanged;
@property (nonatomic, readonly) BOOL nfcMaskChanged;

- (nullable instancetype)initWithTLVRecords:(nonnull NSMutableArray<YKFTLVRecord*> *)records NS_DESIGNATED_INITIALIZER;

+ (NSUInteger)translateFipsMask:(NSUInteger)mask;

@end

#endif /* YKFManagementInterfaceConfiguration_Private_h */
