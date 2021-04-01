//
//  YKFManagementConfiguration.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/4/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFManagementInterfaceConfiguration.h"
#import "YKFManagementReadConfigurationResponse.h"
#import "YKFManagementReadConfigurationResponse+Private.h"
#import "YKFAssert.h"

@interface YKFManagementInterfaceConfiguration()

@property (nonatomic, readwrite) BOOL isConfigurationLocked;

@property (nonatomic, readwrite) NSUInteger usbSupportedMask;
@property (nonatomic, readwrite) NSUInteger nfcSupportedMask;

@property (nonatomic, readwrite) NSUInteger usbEnabledMask;
@property (nonatomic, readwrite) NSUInteger nfcEnabledMask;

@property (nonatomic, readwrite) BOOL usbMaskChanged;
@property (nonatomic, readwrite) BOOL nfcMaskChanged;

@end

@implementation YKFManagementInterfaceConfiguration

- (nullable instancetype)initWithResponse:(nonnull YKFManagementReadConfigurationResponse *)response {
    YKFAssertAbortInit(response);
    self = [super init];
    if (self) {

        self.isConfigurationLocked = false;
        if (response.configurationLocked != nil && response.configurationLocked.length > 0) {
            const char* configBytes = (const char*)[response.configurationLocked bytes];
            for (NSUInteger index = 0; index < response.configurationLocked.length; index++) {
                if (configBytes[index] != 0) {
                    self.isConfigurationLocked = true;
                    break;
                }
            }
        }
        
        self.usbSupportedMask = response.usbSupportedMask;
        self.nfcSupportedMask = response.nfcSupportedMask;
        self.usbEnabledMask = response.usbEnabledMask;
        self.nfcEnabledMask = response.nfcEnabledMask;
    }
    return self;
}

- (BOOL) isSupported: (YKFManagementApplicationType)application overTransport:(YKFManagementTransportType)transport {
    switch (transport) {
        case YKFManagementTransportTypeNFC:
            return (self.nfcSupportedMask & application) == application;
        case YKFManagementTransportTypeUSB:
            return (self.usbSupportedMask & application) == application;
        default:
            YKFAssertReturnValue(true, @"Not supperted transport type", false);
            break;
    }
}

- (BOOL) isEnabled: (YKFManagementApplicationType)application overTransport:(YKFManagementTransportType)transport {
    switch (transport) {
        case YKFManagementTransportTypeNFC:
            return (self.nfcEnabledMask & application) == application;
        case YKFManagementTransportTypeUSB:
            return (self.usbEnabledMask & application) == application;
        default:
            YKFAssertReturnValue(true, @"Not supperted transport type", false);
            break;
    }
}

- (void) setEnabled: (BOOL)newValue application:(YKFManagementApplicationType)application overTransport:(YKFManagementTransportType)transport {
    NSUInteger oldEnabledMask = transport == YKFManagementTransportTypeUSB ? self.usbEnabledMask : self.nfcEnabledMask;
    NSUInteger newEnabledMask = newValue ? (oldEnabledMask | application) : (oldEnabledMask & ~application);

    if (oldEnabledMask == newEnabledMask) {
        // check if there is no changes needs to be applied
        return;
    }

    YKFAssertReturn(!self.isConfigurationLocked, @"Configuration is locked.")
    YKFAssertReturn([self isSupported: application overTransport:transport], @"This YubiKey interface is not supported.")

    switch (transport) {
        case YKFManagementTransportTypeNFC:
            self.nfcEnabledMask = newEnabledMask;
            self.nfcMaskChanged = true;
            break;
        case YKFManagementTransportTypeUSB:
            self.usbEnabledMask = newEnabledMask;
            self.usbMaskChanged = true;
            break;
        default:
            YKFAssertReturn(true, @"Not supperted transport type");
            break;
    }
}

@end
