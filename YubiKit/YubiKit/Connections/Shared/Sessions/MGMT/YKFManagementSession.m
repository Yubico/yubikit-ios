//
//  YKFManagementSession.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/4/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFManagementReadConfigurationResponse.h"
#import "YKFManagementReadConfigurationResponse+Private.h"
#import "YKFManagementWriteAPDU.h"
#import "YKFAssert.h"
#import "YKFAPDUError.h"
#import "YKFManagementSession+Private.h"
#import "YKFSmartCardInterface.h"
#import "YKFSelectApplicationAPDU.h"

@interface YKFManagementSession()

@property (nonatomic, readwrite) YKFVersion *version;
@property (nonatomic, readwrite) YKFSmartCardInterface *smartCardInterface;

- (YKFVersion *)versionFromResponse:(nonnull NSData *)data;

@end

@implementation YKFManagementSession

+ (void)sessionWithConnectionController:(nonnull id<YKFConnectionControllerProtocol>)connectionController
                               completion:(YKFManagementSessionCompletion _Nonnull)completion {
    
    YKFManagementSession *session = [YKFManagementSession new];
    session.smartCardInterface = [[YKFSmartCardInterface alloc] initWithConnectionController:connectionController];
    
    YKFSelectApplicationAPDU *apdu = [[YKFSelectApplicationAPDU alloc] initWithApplicationName:YKFSelectApplicationAPDUNameManagement];
    [session.smartCardInterface selectApplication:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        } else {
            session.version = [session versionFromResponse:data];
            completion(session, nil);
        }
    }];
}

- (void)readConfigurationWithCompletion:(YKFManagementSessionReadCompletionBlock)completion {
    YKFParameterAssertReturn(completion);

    YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0x00 ins:0x1D p1:0x00 p2:0x00 data:[NSData data] type:YKFAPDUTypeShort];
    [self.smartCardInterface executeCommand:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        YKFManagementReadConfigurationResponse *response = [[YKFManagementReadConfigurationResponse alloc]
                                                               initWithKeyResponseData:data
                                                               version:self.version];
        completion(response, nil);
    }];
}

- (void)writeConfiguration:(YKFManagementInterfaceConfiguration*)configuration reboot:(BOOL)reboot completion:(nonnull YKFManagementSessionWriteCompletionBlock)completion {
    YKFParameterAssertReturn(configuration);
    YKFParameterAssertReturn(configuration);
    
    YKFManagementWriteAPDU *apdu = [[YKFManagementWriteAPDU alloc]initWithConfiguration:configuration reboot:reboot];
    
    [self.smartCardInterface executeCommand:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        completion(error);
    }];
}

// No application side state that needs clearing but this will be called when another
// session is replacing the YKFManagementSession.
- (void)clearSessionState {
    ;
}

#pragma mark - Helpers

- (YKFVersion *)versionFromResponse:(nonnull NSData *)data {
    NSString *responseString = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSASCIIStringEncoding];
    NSArray *responseArray = [responseString componentsSeparatedByString:@" "];

    NSAssert(responseArray.count > 0, @"No version number in select management application response");
    NSString *versionString = responseArray.lastObject;

    NSArray *versionArray = [versionString componentsSeparatedByString:@"."];
    NSAssert(versionArray.count == 3, @"Malformed version number: '%@'", versionString);
    
    NSUInteger major = [versionArray[0] intValue];
    NSUInteger minor = [versionArray[1] intValue];
    NSUInteger micro = [versionArray[2] intValue];

    return [[YKFVersion alloc] initWithBytes:(UInt8)major minor:(UInt8)minor micro:(UInt8)micro];
}

@end
