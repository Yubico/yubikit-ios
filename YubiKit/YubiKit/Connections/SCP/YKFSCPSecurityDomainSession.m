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

#import "YKFSCPSecurityDomainSession.h"
#import "YKFSCPSecurityDomainSession+Private.h"
#import "YKFSmartCardInterface.h"
#import "YKFSelectApplicationAPDU.h"
#import "YKFSession+Private.h"
#import "YKFTLVRecord.h"
#import "YKFSCPKeyRef.h"
#import "YKFNSDataAdditions.h"
#import "YKFNSDataAdditions+Private.h"
#import "YKFSCPProcessor.h"
#import "YKFSCPKeyParamsProtocol.h"
#import "YKFSessionError.h"
#import "YKFSessionError+Private.h"

@implementation YKFSecurityDomainSession

+ (void)sessionWithConnectionController:(nonnull id<YKFConnectionControllerProtocol>)connectionController
                               completion:(YKFSecurityDomainSessionCompletion _Nonnull)completion {
    YKFSecurityDomainSession *session = [YKFSecurityDomainSession new];
    session.smartCardInterface = [[YKFSmartCardInterface alloc] initWithConnectionController:connectionController];
    
    YKFSelectApplicationAPDU *apdu = [[YKFSelectApplicationAPDU alloc] initWithApplicationName:YKFSelectApplicationAPDUNameSecurityDomain];
    [session.smartCardInterface selectApplication:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        } else {
            completion(session, nil);
        }
    }];
}

+ (void)sessionWithConnectionController:(nonnull id<YKFConnectionControllerProtocol>)connectionController
                           scpKeyParams:(id<YKFSCPKeyParamsProtocol>)scpKeyParams
                             completion:(YKFSecurityDomainSessionCompletion _Nonnull)completion {
    YKFSecurityDomainSession *session = [YKFSecurityDomainSession new];
    session.smartCardInterface = [[YKFSmartCardInterface alloc] initWithConnectionController:connectionController];
    
    YKFSelectApplicationAPDU *apdu = [[YKFSelectApplicationAPDU alloc] initWithApplicationName:YKFSelectApplicationAPDUNameSecurityDomain];
    [session.smartCardInterface selectApplication:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        } else {
            if (scpKeyParams) {
                [YKFSCPProcessor processorWithSCPKeyParams:scpKeyParams sendRemainingIns:YKFSmartCardInterfaceSendRemainingInsNormal usingSmartCardInterface:session.smartCardInterface completion:^(YKFSCPProcessor * _Nullable processor, NSError * _Nullable error) {
                    if (error) {
                        completion(nil, error);
                    } else {
                        session.smartCardInterface.scpProcessor = processor;
                        completion(session, nil);
                    }
                }];
            } else {
                completion(session, nil);
            }
        }
    }];
}

- (void)getDataWithTag:(UInt16)tag data:(NSData * _Nullable)data  completion:(YKFSecurityDomainSessionDataCompletionBlock)completion {
    YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0 ins:0xca p1:(uint8_t)(tag >> 8) p2:(uint8_t)(tag & 0xff) data:data type:YKFAPDUTypeExtended];
    [self.smartCardInterface executeCommand:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
            completion(data, error);
            return;
    }];
}
 
- (void)getCertificateBundleWithKeyRef:(YKFSCPKeyRef *)keyRef completion:(YKFSecurityDomainSessionCertificateBundleCompletionBlock)completion {
    [self getDataWithTag:0xbf21
                    data:[[YKFTLVRecord alloc] initWithTag:0xa6
                                                     value:[[YKFTLVRecord alloc] initWithTag:0x83 value:keyRef.data].data].data
              completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (!data) {
            completion(nil, error);
            return;
        }
        NSArray<YKFTLVRecord *> *records = [YKFTLVRecord sequenceOfRecordsFromData:data];
        NSMutableArray *certs = [NSMutableArray new];
        for (YKFTLVRecord *record in records) {
            NSData *certData = record.data;
            CFDataRef cfCertDataRef =  (__bridge CFDataRef)certData;
            SecCertificateRef certificate = SecCertificateCreateWithData(NULL, cfCertDataRef);
            if (certificate) {
                [certs addObject:(__bridge id)certificate];
                CFRelease(certificate);
            }
        }
        if (records.count != certs.count) {
            completion(nil, [YKFSessionError errorWithCode:YKFSessionErrorUnexpectedResult]);
            return;
        }
        completion(certs, nil);
    }];
 }

- (void)clearSessionState { 
    ;
}

@end
