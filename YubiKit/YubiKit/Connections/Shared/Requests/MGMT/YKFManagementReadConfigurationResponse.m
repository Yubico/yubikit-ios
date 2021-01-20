//
//  YKFManagementReadConfigurationResponse.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/3/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFManagementReadConfigurationResponse.h"
#import "YKFManagementReadConfigurationResponse+Private.h"
#import "YKFAssert.h"
#import "YKFNSDataAdditions+Private.h"
#import "YKFManagementInterfaceConfiguration+Private.h"

@interface YKFManagementReadConfigurationResponse()

@property (nonatomic, readwrite, nonnull) YKFVersion *version;
@property (nonatomic, readwrite) NSUInteger serialNumber;
@property (nonatomic, readwrite) NSUInteger formFactor;

@end

@implementation YKFManagementReadConfigurationResponse

- (nullable instancetype)initWithKeyResponseData:(nonnull NSData *)responseData version:(YKFVersion *)version {
    YKFAssertAbortInit(responseData.length);
    YKFAssertAbortInit(version)
    
    self = [super init];
    if (self) {
        // skipping first byte
        NSRange range = NSMakeRange(1, responseData.length - 1);        
        responseData = [responseData subdataWithRange:range];
                            
        UInt8 *responseBytes = (UInt8 *)responseData.bytes;
        NSUInteger readIndex = 0;

        // setting default version that received from selection of management application on YubiKey
        // this value may be overriden with whatever returned with reading configuration command response
        self.version = version;
        while (readIndex < responseData.length) {
            UInt8 responseTag = responseBytes[readIndex];

            ++readIndex;
            YKFAssertAbortInit([responseData ykf_containsIndex:readIndex]);

            UInt8 tagLength = responseBytes[readIndex];
            YKFAssertAbortInit(tagLength > 0);
            
            ++readIndex;
            NSRange tagValueRange = NSMakeRange(readIndex, tagLength);
            YKFAssertAbortInit([responseData ykf_containsRange:tagValueRange]);
            NSData* value = [responseData subdataWithRange:tagValueRange];
            UInt8* valueBytes = (UInt8*)value.bytes;

            switch (responseTag) {
                case YKFManagementReadConfigurationTagsUsbEnabled:
                    self.usbEnabledMask = [value ykf_integerValue];
                    break;

                case YKFManagementReadConfigurationTagsUsbSupported:
                    self.usbSupportedMask = [value ykf_integerValue];
                    break;

                case YKFManagementReadConfigurationTagsSerialNumber:
                    self.serialNumber = [value ykf_integerValue];
                    break;

                case YKFManagementReadConfigurationTagsFormFactor:
                    self.formFactor = [value ykf_integerValue];
                    break;

                case YKFManagementReadConfigurationTagsFirmwareVersion:
                    YKFAssertAbortInit(tagLength == 3);
                    self.version = [[YKFVersion alloc] initWithBytes:valueBytes[0] minor:valueBytes[1] micro:valueBytes[2]];
                    break;

                case YKFManagementReadConfigurationTagsConfigLocked:
                    self.configurationLocked = value;
                    break;

                case YKFManagementReadConfigurationTagsNfcEnabled:
                    self.nfcEnabledMask = [value ykf_integerValue];
                    break;

                case YKFManagementReadConfigurationTagsNfcSupported:
                    self.nfcSupportedMask = [value ykf_integerValue];
                    break;

                default:
                    break;
            }
            
            readIndex += tagLength;
        }
    }
    return self;
}

- (nullable YKFManagementInterfaceConfiguration*)configuration {   
    return [[YKFManagementInterfaceConfiguration alloc] initWithResponse:self];
}

@end
