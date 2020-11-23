//
//  YKFKeyManagementSession.m
//  YubiKit
//
//  Created by Irina Makhalova on 2/4/20.
//  Copyright © 2020 Yubico. All rights reserved.
//

#import "YKFKeyManagementRequest.h"
#import "YKFKeyManagementRequest+Private.h"
#import "YKFKeyManagementReadConfigurationRequest.h"
#import "YKFKeyManagementReadConfigurationResponse.h"
#import "YKFKeyManagementReadConfigurationResponse+Private.h"
#import "YKFKeyManagementWriteConfigurationRequest.h"
#import "YKFAssert.h"
#import "YKFKeyAPDUError.h"
#import "YKFKeyManagementSession+Private.h"
#import "YKFSmartCardInterface.h"
#import "YKFSelectApplicationAPDU.h"

@interface YKFKeyManagementSession()

@property (nonatomic, readwrite) YKFKeyVersion *version;
@property (nonatomic, readwrite) YKFSmartCardInterface *smartCardInterface;

- (YKFKeyVersion *)versionFromResponse:(nonnull NSData *)data;

@end

@implementation YKFKeyManagementSession

+ (void)sessionWithConnectionController:(nonnull id<YKFKeyConnectionControllerProtocol>)connectionController
                               completion:(YKFKeyManagementSessionCompletion _Nonnull)completion {
    
    YKFKeyManagementSession *session = [YKFKeyManagementSession new];
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

- (void)readConfigurationWithCompletion:(YKFKeyManagementSessionReadCompletionBlock)completion {
    YKFParameterAssertReturn(completion);

    YKFKeyManagementReadConfigurationRequest* request = [[YKFKeyManagementReadConfigurationRequest alloc] init];
    
    
    [self.smartCardInterface executeCommand:request.apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        YKFKeyManagementReadConfigurationResponse *response = [[YKFKeyManagementReadConfigurationResponse alloc]
                                                               initWithKeyResponseData:data
                                                               version:self.version];
        completion(response, nil);
    }];
}

- (void) writeConfiguration:(YKFManagementInterfaceConfiguration*)configuration reboot:(BOOL)reboot completion:(nonnull YKFKeyManagementSessionWriteCompletionBlock)completion {
    YKFParameterAssertReturn(configuration);
    YKFParameterAssertReturn(configuration);
    
    YKFKeyManagementWriteConfigurationRequest* request = [[YKFKeyManagementWriteConfigurationRequest alloc]
                                                          initWithConfiguration: configuration
                                                          reboot: reboot];
    
    [self.smartCardInterface executeCommand:request.apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        completion(error);
    }];
}

// No state that needs clearing but this will be called when another
// session is replacing the YKFKeyManagementSession.
- (void)clearSessionState {
    ;
}

#pragma mark - Helpers

- (YKFKeyVersion *)versionFromResponse:(nonnull NSData *)data {
    NSString *responseString = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSASCIIStringEncoding];
    NSArray *responseArray = [responseString componentsSeparatedByString:@" "];

    NSAssert(responseArray.count > 0, @"No version number in select management application response");
    NSString *versionString = responseArray.lastObject;

    NSArray *versionArray = [versionString componentsSeparatedByString:@"."];
    NSAssert(versionArray.count == 3, @"Malformed version number: '%@'", versionString);
    
    NSUInteger major = [versionArray[0] intValue];
    NSUInteger minor = [versionArray[1] intValue];
    NSUInteger micro = [versionArray[2] intValue];

    return [[YKFKeyVersion alloc] initWithBytes:(UInt8)major minor:(UInt8)minor micro:(UInt8)micro];
}

@end
