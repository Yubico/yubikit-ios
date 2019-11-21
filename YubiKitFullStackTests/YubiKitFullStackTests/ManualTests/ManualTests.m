//
//  ManualTests.m
//  YubiKitFullStackTests
//
//  Created by Conrad Ciobanica on 2018-05-16.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import "ManualTests.h"
#import "TestSharedLogger.h"
#import "KeyCommandResponseParser.h"

typedef NS_ENUM(NSUInteger, ManualTestsInstruction) {
    ManualTestsInstructionU2FPing = 0x40
};

@implementation ManualTests

#pragma mark - Test setup

- (void)setupTestList {
    NSMutableArray *echoTests = [[NSMutableArray alloc] init];
    
    //// -------------------------------------------------------------------------------------------------------------------------------------------------------
    //// Ping/echo tests
    
    // Short echo test
    NSValue *shortEchoTestSelector = [NSValue valueWithPointer:@selector(testEcho_WhenSendingAShortValue_ValueIsReceivedBack)];
    NSArray *shortEchoTestEntry = @[@"Echo test #1", @"Short value echo test.", shortEchoTestSelector];
    [echoTests addObject:shortEchoTestEntry];

    // Repeated short echo test
    NSValue *repeatedShortEchoTestSelector = [NSValue valueWithPointer:@selector(testEcho_WhenSendingTheSameValueMultipleTimes_ValueIsReceivedBack)];
    NSArray *repeatedShortEchoTestEntry = @[@"Echo test #2", @"Repeated short value echo test.", repeatedShortEchoTestSelector];
    [echoTests addObject:repeatedShortEchoTestEntry];

    // Ping with length in interval
    NSValue *intervalEchoTestSelector = [NSValue valueWithPointer:@selector(testEcho_WhenSendingValuesInAnInterval_ValuesAreReceivedBack)];
    NSArray *intervalEchoTestEntry = @[@"Echo test #3", @"Interval random data echo test.", intervalEchoTestSelector];
    [echoTests addObject:intervalEchoTestEntry];
    
    // Ping incrementing values with length in interval
    NSValue *incrementingIntervalEchoTestSelector = [NSValue valueWithPointer:@selector(testEcho_WhenSendingIncrementingValuesInAnInterval_ValuesAreReceivedBack)];
    NSArray *incrementingIntervalEchoTestEntry = @[@"Echo test #4", @"Incrementing interval echo test.", incrementingIntervalEchoTestSelector];
    [echoTests addObject:incrementingIntervalEchoTestEntry];

    //// -------------------------------------------------------------------------------------------------------------------------------------------------------
    //// Unknown data tests
    
    NSMutableArray *unknownDataTests = [[NSMutableArray alloc] init];
    
    // Send unknown data
    NSValue *unknownInsTestSelector = [NSValue valueWithPointer:@selector(test_WhenSendingUnknownData_ErrorIsReceivedBack)];
    NSArray *unknownInsTestEntry = @[@"Unknown instruction test #1", @"Sending unknown instruction test.", unknownInsTestSelector];
    [unknownDataTests addObject:unknownInsTestEntry];
    
    // Send unknown data in a burst
    NSValue *repeatedUnknownInsTestSelector = [NSValue valueWithPointer:@selector(test_WhenSendingUnknownDataRepeatedly_ErrorIsReceivedBack)];
    NSArray *repeatedUnknownInsTestEntry = @[@"Unknown instruction test #2", @"Repeated unknown instruction test.", repeatedUnknownInsTestSelector];
    [unknownDataTests addObject:repeatedUnknownInsTestEntry];

    // Unknown CLA
    NSValue *repeatedUnknownClaTestSelector = [NSValue valueWithPointer:@selector(test_WhenSendingUnknownCLA_ErrorIsReceivedBack)];
    NSArray *repeatedUnknownClaTestEntry = @[@"Unknown CLA test #1", @"Sending unknown CLA test.", repeatedUnknownClaTestSelector];
    [unknownDataTests addObject:repeatedUnknownClaTestEntry];
    
    //// -------------------------------------------------------------------------------------------------------------------------------------------------------
    //// Application versions
    
    NSMutableArray *applicationVersionTests = [[NSMutableArray alloc] init];
    
    // Request application version
    NSValue *u2fApplicationVersionTestSelector = [NSValue valueWithPointer:@selector(test_WhenRequestingU2FApplicationVersion_VersionIsReceivedBack)];
    NSArray *u2fApplicationVersionTestEntry = @[@"U2F application version test #1", @"Request U2F application version.", u2fApplicationVersionTestSelector];
    [applicationVersionTests addObject:u2fApplicationVersionTestEntry];
    
    //// -------------------------------------------------------------------------------------------------------------------------------------------------------
    //// OATH tests
    
    NSMutableArray *oathTests = [[NSMutableArray alloc] init];
    
    // Add credential and calculate
    NSValue *oathAddAndCalculateSelector = [NSValue valueWithPointer:@selector(test_WhenAddingAnOATHCredential_CredentialIsAddedToTheKeyAndValueCanBeComputed)];
    NSArray *oathAddAndCalculateTestEntry = @[@"OATH Put and Calculate", @"Puts, calculates and removes a credential.", oathAddAndCalculateSelector];
    [oathTests addObject:oathAddAndCalculateTestEntry];
    
    //// -------------------------------------------------------------------------------------------------------------------------------------------------------
    //// Challenge/Response tests
    NSMutableArray *chalRespTests = [[NSMutableArray alloc] init];

    // Do hmac challenge response in slot 1, assumes a secret is already programmed
    NSValue *hmacChalSlot1Resp = [NSValue valueWithPointer:@selector(test_WhenSendingChallengeToSlot1_KeySendsHmacResponse)];
    NSArray *hmacChalSlot1RespTestEntry = @[@"HMAC Chal", @"Performs a Challenge/Response.", hmacChalSlot1Resp];
    [chalRespTests addObject:hmacChalSlot1RespTestEntry];

    //// -------------------------------------------------------------------------------------------------------------------------------------------------------
    //// PIV tests
    NSMutableArray *pivTests = [[NSMutableArray alloc] init];

    // Do rsa sig
    NSValue *pivGenAuthRsaSig = [NSValue valueWithPointer:@selector(test_WhenSendingGeneralAuthToSlot1_KeySendsRsaSig)];
    NSArray *pivGenAuthRsaSigTestEntry = @[@"PIV Verify Pin and General Auth", @"Performs an RSA signature.", pivGenAuthRsaSig];
    [pivTests addObject:pivGenAuthRsaSigTestEntry];

    //// -------------------------------------------------------------------------------------------------------------------------------------------------------
    //// FIDO2 tests

    NSMutableArray *fido2Tests = [[NSMutableArray alloc] init];

    // Reset
    NSValue *fido2Reset = [NSValue valueWithPointer:@selector(test_WhenCallingFIDO2Reset_KeyApplicationResets)];
    NSArray *fido2ResetTestEntry = @[@"FIDO2 Reset", @"Resets the FIDO2 application.", fido2Reset];
    [fido2Tests addObject:fido2ResetTestEntry];
    
    // Get Info
    NSValue *fido2GetInfoSelector = [NSValue valueWithPointer:@selector(test_WhenCallingFIDO2GetInfo_TheKeyReturnsAutheticatorProperties)];
    NSArray *fido2GetInfoTestEntry = @[@"FIDO2 Get Info", @"Requests authenticator properties.", fido2GetInfoSelector];
    [fido2Tests addObject:fido2GetInfoTestEntry];
    
    // Make credential test #1
    NSValue *fido2MakeCredentialSelectorECNoRK = [NSValue valueWithPointer:@selector(test_WhenAdingFIDO2Credential_ECCNonRKCredentialIsAddedToTheKey)];
    NSArray *fido2MakeCredentialTestEntry1 = @[@"FIDO2 Make Credential (ECC)", @"Creates a FIDO2 credential: ECC, non-RK.", fido2MakeCredentialSelectorECNoRK];
    [fido2Tests addObject:fido2MakeCredentialTestEntry1];

    // Make credential test #2
    NSValue *fido2MakeCredentialSelectorEdDSA = [NSValue valueWithPointer:@selector(test_WhenAdingFIDO2Credential_EdDSACredentialIsAddedToTheKey)];
    NSArray *fido2MakeCredentialTestEntry2 = @[@"FIDO2 Make Credential (EdDSA, Ed25519)", @"Creates a FIDO2 credential: Ed25519, RK.", fido2MakeCredentialSelectorEdDSA];
    [fido2Tests addObject:fido2MakeCredentialTestEntry2];

    // Get assertion test #1
    NSValue *fido2ECCGetAssertionSelector = [NSValue valueWithPointer:@selector(test_AfterAdingECCFIDO2Credential_SignatureCanBeRequested)];
    NSArray *fido2ECCGetAssertionTestEntry = @[@"FIDO2 Get Assertion (ECC)", @"Gets an Assertion after creating credential: ECC, non-RK.", fido2ECCGetAssertionSelector];
    [fido2Tests addObject:fido2ECCGetAssertionTestEntry];

    // Get assertion test #2
    NSValue *fido2EdDSAGetAssertionSelector = [NSValue valueWithPointer:@selector(test_AfterAdingEdDSAFIDO2Credential_SignatureCanBeRequested)];
    NSArray *fido2EdDSAGetAssertionTestEntry = @[@"FIDO2 Get Assertion (EdDSA, Ed25519)", @"Gets an Assertion after creating credential: Ed25519, RK.", fido2EdDSAGetAssertionSelector];
    [fido2Tests addObject:fido2EdDSAGetAssertionTestEntry];

    // Get assertion test #3
    NSValue *fido2ECCSilentGetAssertionSelector = [NSValue valueWithPointer:@selector(test_AfterAdingECCFIDO2Credential_SilentSignatureCanBeRequested)];
    NSArray *fido2ECCSilentGetAssertionTestEntry = @[@"FIDO2 Silent Get Assertion (ECC)", @"Gets a Silent Assertion after creating credential: ECC, non-RK.",
                                                     fido2ECCSilentGetAssertionSelector];
    [fido2Tests addObject:fido2ECCSilentGetAssertionTestEntry];
    
    //// -------------------------------------------------------------------------------------------------------------------------------------------------------
    //// Touch tests

    NSMutableArray *touchTests = [[NSMutableArray alloc] init];
    
    // CCID Touch
    NSValue *ccidTouchTest = [NSValue valueWithPointer:@selector(test_WhenTouchIsRequiredForCCID_TouchIsDetected)];
    NSArray *ccidTouchTestEntry = @[@"CCID Touch Test", @"Tests the touch detection for CCID.", ccidTouchTest];
    [touchTests addObject:ccidTouchTestEntry];
    
    //// -------------------------------------------------------------------------------------------------------------------------------------------------------
    //// Set the list
    
    self.testList = @[@[@"Echo tests", echoTests],
                      @[@"Unknown data tests", unknownDataTests],
                      @[@"Application version tests", applicationVersionTests],
                      @[@"OATH Tests", oathTests],
                      @[@"Chal/Resp Tests", chalRespTests],
                      @[@"PIV Tests", pivTests],
                      @[@"Touch Tests", touchTests],
                      @[@"FIDO2 Tests", fido2Tests]];
}

#pragma mark - Echo Tests

- (void)testEcho_WhenSendingAShortValue_ValueIsReceivedBack {
    [self executeU2FApplicationSelection];
    [self pingKeyWithRandomDataLength:20];
    [TestSharedLogger.shared logSepparator];
}

- (void)testEcho_WhenSendingTheSameValueMultipleTimes_ValueIsReceivedBack {
    [self executeU2FApplicationSelection];
    
    for (int i = 0; i < 100; ++i) {
        BOOL timeout = [self pingKeyWithRandomDataLength:20];
        if (timeout) { break; }
    }
}

- (void)testEcho_WhenSendingValuesInAnInterval_ValuesAreReceivedBack {
    [self executeU2FApplicationSelection];
    for (int dataLength = 1; dataLength <= 1024; ++dataLength) {
        BOOL timeout = [self pingKeyWithRandomDataLength:dataLength];
        if (timeout) { break; }
    }
}

- (void)testEcho_WhenSendingIncrementingValuesInAnInterval_ValuesAreReceivedBack {
    [self executeU2FApplicationSelection];
    for (int dataLength = 1; dataLength <= 1024; ++dataLength) {
        BOOL timeout = [self pingKeyWithIncrementingDataLength:dataLength];
        if (timeout) { break; }
    }
}

#pragma mark - Unknown data tests

- (void)test_WhenSendingUnknownData_ErrorIsReceivedBack {
    [self executeU2FApplicationSelection];
    
    NSString *hexString = @"0000000000000000000000000000000000";
    NSData *data = [self.testDataGenerator dataFromHexString:hexString];
    
    [TestSharedLogger.shared logMessage:@"Sent to key data: %@", hexString];
    
    [self executeCommandWithData:data completion:^(NSData *response, NSError *error) {
        if (error) {
            [TestSharedLogger.shared logError: @"Error: %@", error.localizedDescription];
            return;
        }
        NSUInteger statusCode = [KeyCommandResponseParser statusCodeFromData:response];
        
        if (statusCode == YKFKeyAPDUErrorCodeInsNotSupported) {
            [TestSharedLogger.shared logSuccess:@"Received instruction not supported."];
        } else {
            [TestSharedLogger.shared logError:@"Received wrong response status."];
        }
    }];
}

- (void)test_WhenSendingUnknownDataRepeatedly_ErrorIsReceivedBack {
    [self executeU2FApplicationSelection];
    
    NSString *hexString = @"0000000000000000000000000000000000";
    NSData *data = [self.testDataGenerator dataFromHexString:hexString];
    
    [TestSharedLogger.shared logMessage:@"Sent to key data: %@", hexString];
    
    for (int i = 0; i < 5; ++i) {
        [self executeCommandWithData:data completion:^(NSData *response, NSError *error) {
            if (error) {
                [TestSharedLogger.shared logError: @"Error: %@", error.localizedDescription];
                return;
            }
            NSUInteger statusCode = [KeyCommandResponseParser statusCodeFromData:response];
            
            if (statusCode == YKFKeyAPDUErrorCodeInsNotSupported) {
                [TestSharedLogger.shared logSuccess:@"Received instruction not supported."];
            } else {
                [TestSharedLogger.shared logError:@"Received wrong response status."];
            }
        }];
    }
}

- (void)test_WhenSendingUnknownCLA_ErrorIsReceivedBack {
    [self executeU2FApplicationSelection];
    
    NSString *hexString = @"B4030000000000";
    NSData *data = [self.testDataGenerator dataFromHexString:hexString];
    
    [TestSharedLogger.shared logMessage:@"Sent to key data: %@", hexString];
    
    [self executeCommandWithData:data completion:^(NSData *response, NSError *error) {
        if (error) {
            [TestSharedLogger.shared logError: @"Error: %@", error.localizedDescription];
            return;
        }
        NSUInteger statusCode = [KeyCommandResponseParser statusCodeFromData:response];
        
        if (statusCode == YKFKeyAPDUErrorCodeCLANotSupported) {
            [TestSharedLogger.shared logSuccess:@"Received CLA not supported."];
        } else {
            [TestSharedLogger.shared logError:@"Received wrong response status."];
        }
    }];
}

- (void)test_WhenRequestingU2FApplicationVersion_VersionIsReceivedBack {
    [self executeU2FApplicationSelection];
    
    NSString *hexString = @"00030000";
    NSData *data = [self.testDataGenerator dataFromHexString:hexString];
    
    [TestSharedLogger.shared logMessage:@"Sent to key data: %@", hexString];
    
    [self executeCommandWithData:data completion:^(NSData *response, NSError *error) {
        if (error) {
            [TestSharedLogger.shared logError: @"Error: %@", error.localizedDescription];
            return;
        }
        NSUInteger statusCode = [KeyCommandResponseParser statusCodeFromData:response];
        
        if (statusCode == YKFKeyAPDUErrorCodeNoError) {
            [TestSharedLogger.shared logSuccess:@"Received application version."];
        } else {
            [TestSharedLogger.shared logError:@"Received wrong response status."];
        }
    }];
}

#pragma mark - OATH Tests

- (void)test_WhenAddingAnOATHCredential_CredentialIsAddedToTheKeyAndValueCanBeComputed {
    // This is an URL conforming to Key URI Format specs.
    NSString *oathUrlString = @"otpauth://totp/Yubico:example@yubico.com?secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=Yubico&algorithm=SHA1&digits=6&period=30";
    NSURL *url = [NSURL URLWithString:oathUrlString];
    if (!url) {
        [TestSharedLogger.shared logError:@"Invalid OATH URL."];
        return;
    }
    
    // Create the credential from the URL using the convenience initializer.
    YKFOATHCredential *credential = [[YKFOATHCredential alloc] initWithURL:url];
    if (!credential) {
        [TestSharedLogger.shared logError:@"Could not create OATH credential."];
        return;
    }
    id<YKFKeyOATHServiceProtocol> oathService = YubiKitManager.shared.accessorySession.oathService;
    
    /*
     1. Add the credential to the key
     */
    
    YKFKeyOATHPutRequest *putRequest = [[YKFKeyOATHPutRequest alloc] initWithCredential:credential];
    
    [oathService executePutRequest:putRequest completion:^(NSError * _Nullable error) {
        if (error) {
            [TestSharedLogger.shared logError:@"Could not add the credential to the key."];
            return;
        }
        [TestSharedLogger.shared logSuccess:@"The credential was added to the key."];
    }];
    
    
    /*
     2. Calculate the credential.
     */
    YKFKeyOATHCalculateRequest *calculateRequest = [[YKFKeyOATHCalculateRequest alloc] initWithCredential:credential];
    
    [oathService executeCalculateRequest:calculateRequest completion:^(YKFKeyOATHCalculateResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            [TestSharedLogger.shared logError:@"Could not calculate the credential."];
            return;
        }
        NSString *successLog = [NSString stringWithFormat:@"OTP value for the credential %@ is %@", credential.label, response.otp];
        [TestSharedLogger.shared logSuccess:successLog];
    }];
    
    /*
     3. Remove the credential.
     */
    YKFKeyOATHDeleteRequest *deleteRequest = [[YKFKeyOATHDeleteRequest alloc] initWithCredential:credential];
    
    [oathService executeDeleteRequest:deleteRequest completion:^(NSError * _Nullable error) {
        if (error) {
            [TestSharedLogger.shared logError:@"Could not delete the credential."];
            return;
        }
        [TestSharedLogger.shared logSuccess:@"The credential was removed from the key."];
    }];
}

#pragma mark - Challenge/Response Tests

// HMAC-SHA1 with f6d6475b48b94f0d849a6c19bf8cc7f0d62255a0 as a secret
// Challenge/Response: challenge/0e2df6bacc23764aeb3d9792ed17b063c7d254fa

- (void)test_WhenSendingChallengeToSlot1_KeySendsHmacResponse {
    NSString *hexString = @"313233343536";
    NSData *data = [self.testDataGenerator dataFromHexString:hexString];

    [self executeYubiKeyApplicationSelection];

    YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0 ins:0x01 p1:0x30 p2:0 data:data type:YKFAPDUTypeShort];

    [self executeCommandWithAPDU:apdu completion:^(NSData *result, NSError *error) {
        if (error) {
            [TestSharedLogger.shared logError: @"When requesting challenge: %@", error.localizedDescription];
            return;
        }
        [TestSharedLogger.shared logMessage:@"Received data length: %d", result.length];

        NSData *respData = [result subdataWithRange:NSMakeRange(0, result.length - 2)];
        [TestSharedLogger.shared logMessage:@"Challenge data:\n%@", data];
        [TestSharedLogger.shared logMessage:@"Response data:\n%@", respData];
    }];
}

#pragma mark - Piv Tests

- (void)test_WhenSendingGeneralAuthToSlot1_KeySendsRsaSig {
    NSString *hexString = @"313233343536ffff";
    NSData *data = [self.testDataGenerator dataFromHexString:hexString];

    [self executePivApplicationSelection];

    YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0x00 ins:0x20 p1:0x00 p2:0x80 data:data type:YKFAPDUTypeShort];

    [self executeCommandWithAPDU:apdu completion:^(NSData *result, NSError *error) {
        if (error) {
            [TestSharedLogger.shared logError: @"Failed pin verification: %@", error.localizedDescription];
            return;
        }
        [TestSharedLogger.shared logMessage:@"Received data length: %d", result.length];

        NSData *respData = [result subdataWithRange:NSMakeRange(0, result.length - 2)];
        [TestSharedLogger.shared logMessage:@"Sent data:\n%@", data];
        [TestSharedLogger.shared logMessage:@"Received data:\n%@", respData];
    }];

    hexString = @"7c8201068200818201000001ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff003031300d060960864801650304020105000420c6b7edaa05038235152a79711e34f64e0d0b01e5c3";

    data = [self.testDataGenerator dataFromHexString:hexString];

    apdu = [[YKFAPDU alloc] initWithCla:0x10 ins:0x87 p1:0x07 p2:0x9a data:data type:YKFAPDUTypeShort];

    [self executeCommandWithAPDU:apdu completion:^(NSData *result, NSError *error) {
        if (error) {
            [TestSharedLogger.shared logError: @"Failed sig: %@", error.localizedDescription];
            return;
        }
        [TestSharedLogger.shared logMessage:@"Received data length: %d", result.length];

        NSData *respData = [result subdataWithRange:NSMakeRange(0, result.length - 2)];
        [TestSharedLogger.shared logMessage:@"Sent data:\n%@", data];
        [TestSharedLogger.shared logMessage:@"Received data:\n%@", respData];
    }];

    hexString = @"952cb588b3dbbf0d23009400";

    data = [self.testDataGenerator dataFromHexString:hexString];

    apdu = [[YKFAPDU alloc] initWithCla:0x00 ins:0x87 p1:0x07 p2:0x9a data:data type:YKFAPDUTypeShort];

    [self executeCommandWithAPDU:apdu completion:^(NSData *result, NSError *error) {
        if (error) {
            [TestSharedLogger.shared logError: @"Failed sig: %@", error.localizedDescription];
            return;
        }
        [TestSharedLogger.shared logMessage:@"Received data length: %d", result.length];

        NSData *respData = [result subdataWithRange:NSMakeRange(0, result.length - 2)];
        [TestSharedLogger.shared logMessage:@"Sent data:\n%@", data];
        [TestSharedLogger.shared logMessage:@"Received data:\n%@", respData];
    }];

    hexString = @"00000000000000000000";

    data = [self.testDataGenerator dataFromHexString:hexString];

    apdu = [[YKFAPDU alloc] initWithCla:0x00 ins:0xc0 p1:0x00 p2:0x00 data:data type:YKFAPDUTypeShort];

    [self executeCommandWithAPDU:apdu completion:^(NSData *result, NSError *error) {
        if (error) {
            [TestSharedLogger.shared logError: @"Failed sig: %@", error.localizedDescription];
            return;
        }
        [TestSharedLogger.shared logMessage:@"Received data length: %d", result.length];

        NSData *respData = [result subdataWithRange:NSMakeRange(0, result.length - 2)];
        [TestSharedLogger.shared logMessage:@"Sent data:\n%@", data];
        [TestSharedLogger.shared logMessage:@"Received data:\n%@", respData];
    }];
}

#pragma mark - FIDO2 Tests

- (void)test_WhenCallingFIDO2Reset_KeyApplicationResets {
    [YubiKitManager.shared.accessorySession.fido2Service executeResetRequestWithCompletion:^(NSError * _Nullable error) {
        if (error) {
            [TestSharedLogger.shared logMessage:@"Reset request ended in error: %ld - %@.", error.code, error.localizedDescription];
            return;
        }
        [TestSharedLogger.shared logMessage:@"Reset request successful."];
    }];
}

- (void)test_WhenCallingFIDO2GetInfo_TheKeyReturnsAutheticatorProperties {
    __weak typeof(self) weakSelf = self;
    [YubiKitManager.shared.accessorySession.fido2Service executeGetInfoRequestWithCompletion:^(YKFKeyFIDO2GetInfoResponse *response, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            [TestSharedLogger.shared logMessage:@"Get Info request ended in error: %ld - %@.", error.code, error.localizedDescription];
            return;
        }
        
        [TestSharedLogger.shared logMessage:@"Get Info request successful."];
        [strongSelf logFIDO2GetInfoResponse:response];
    }];
}

- (void)test_WhenAdingFIDO2Credential_ECCNonRKCredentialIsAddedToTheKey {
    NSDictionary *makeCredentialOptions = @{YKFKeyFIDO2MakeCredentialRequestOptionRK: @(NO)};
    
    [self addFIDO2CredentialWithAlg:YKFFIDO2PublicKeyAlgorithmES256 options:makeCredentialOptions];
}

- (void)test_WhenAdingFIDO2Credential_EdDSACredentialIsAddedToTheKey {
    NSDictionary *makeCredentialOptions = @{YKFKeyFIDO2MakeCredentialRequestOptionRK: @(NO)};
    
    [self addFIDO2CredentialWithAlg:YKFFIDO2PublicKeyAlgorithmEdDSA options:makeCredentialOptions];
}

- (void)test_AfterAdingECCFIDO2Credential_SignatureCanBeRequested {
    NSDictionary *makeCredentialOptions = @{YKFKeyFIDO2MakeCredentialRequestOptionRK: @(NO)};
    NSDictionary *getAssertionOptions = @{YKFKeyFIDO2GetAssertionRequestOptionUP: @(YES),
                                          YKFKeyFIDO2GetAssertionRequestOptionUV: @(NO)};
    
    [self addFIDO2CredentialWithAlg:YKFFIDO2PublicKeyAlgorithmES256 options:makeCredentialOptions getAssertionOptions:getAssertionOptions];
}

- (void)test_AfterAdingEdDSAFIDO2Credential_SignatureCanBeRequested {
    NSDictionary *makeCredentialOptions = @{YKFKeyFIDO2MakeCredentialRequestOptionRK: @(YES)};
    NSDictionary *getAssertionOptions = @{YKFKeyFIDO2GetAssertionRequestOptionUP: @(YES),
                                          YKFKeyFIDO2GetAssertionRequestOptionUV: @(NO)};
    
    [self addFIDO2CredentialWithAlg:YKFFIDO2PublicKeyAlgorithmEdDSA options:makeCredentialOptions getAssertionOptions:getAssertionOptions];
}

- (void)test_AfterAdingECCFIDO2Credential_SilentSignatureCanBeRequested {
    NSDictionary *makeCredentialOptions = @{YKFKeyFIDO2MakeCredentialRequestOptionRK: @(NO)};
    NSDictionary *getAssertionOptions = @{YKFKeyFIDO2GetAssertionRequestOptionUP: @(NO),
                                          YKFKeyFIDO2GetAssertionRequestOptionUV: @(NO)};
    
    [self addFIDO2CredentialWithAlg:YKFFIDO2PublicKeyAlgorithmES256 options:makeCredentialOptions getAssertionOptions:getAssertionOptions];
}

#pragma mark - Touch Tests

- (void)test_WhenTouchIsRequiredForCCID_TouchIsDetected {
    static const NSUInteger aidSize = 8;
    static const UInt8 aid[aidSize] = {0xA0, 0x00, 0x00, 0x05, 0x27, 0x47, 0x11, 0x17};
    NSData *data = [NSData dataWithBytes:aid length:aidSize];
    YKFAPDU *selectAPDU = [[YKFAPDU alloc] initWithCla:0x00 ins:0xA4 p1:0x04 p2:0x00 data:data type:YKFAPDUTypeShort];
    
    __weak typeof(self) weakSelf = self;
    [self executeCommandWithAPDU:selectAPDU completion:^(NSData *response, NSError *error) {
        if (error) {
            [TestSharedLogger.shared logError: @"Could not select the management application."];
        } else {
            [TestSharedLogger.shared logSuccess: @"Management application successfully selected."];
            [TestSharedLogger.shared logMessage: @"Touch the key to test touch detection..."];
            
            YKFAPDU *touchTestAPDU = [[YKFAPDU alloc] initWithCla:0x00 ins:0x06 p1:0x00 p2:0x00 data:[NSData data] type:YKFAPDUTypeShort];
            [weakSelf executeCommandWithAPDU:touchTestAPDU completion:^(NSData *response, NSError *error) {
                if (error) {
                    [TestSharedLogger.shared logError:@"Touch test returned error %d - %@.", error.code, error.localizedDescription];
                } else {
                    [TestSharedLogger.shared logSuccess:@"The touch was successfully detected."];
                }
            }];
        }
    }];
}

#pragma mark - FIDO2 Command Helpers

- (void)addFIDO2CredentialWithAlg:(NSInteger)alg options:(NSDictionary *)options getAssertionOptions:(NSDictionary *)assertionOptions {
    YKFKeyFIDO2GetAssertionRequest *getAssertionRequest = [[YKFKeyFIDO2GetAssertionRequest alloc] init];
    YKFKeyFIDO2MakeCredentialRequest *makeCredentialRequest = [[YKFKeyFIDO2MakeCredentialRequest alloc] init];
    
    UInt8 *buffer = malloc(32);
    if (!buffer) {
        return;
    }
    memset(buffer, 0, 32);
    NSData *data = [NSData dataWithBytes:buffer length:32];
    free(buffer);
    
    // Make Credential Request Params
    
    makeCredentialRequest.clientDataHash = data;
    
    YKFFIDO2PublicKeyCredentialRpEntity *rp = [[YKFFIDO2PublicKeyCredentialRpEntity alloc] init];
    rp.rpId = @"example.com";
    rp.rpName = @"Acme";
    makeCredentialRequest.rp = rp;
    
    YKFFIDO2PublicKeyCredentialUserEntity *user = [[YKFFIDO2PublicKeyCredentialUserEntity alloc] init];
    user.userId = data;
    user.userName = @"johnpsmith@example.com";
    user.userDisplayName = @"John P. Smith";
    makeCredentialRequest.user = user;
    
    YKFFIDO2PublicKeyCredentialParam *param = [[YKFFIDO2PublicKeyCredentialParam alloc] init];
    param.alg = alg;
    makeCredentialRequest.pubKeyCredParams = @[param];
    
    makeCredentialRequest.options = options;
    
    // Get Assertion Request Params
    
    getAssertionRequest.rpId = @"example.com";
    getAssertionRequest.clientDataHash = data;
    getAssertionRequest.options = assertionOptions;
    
    __weak typeof(self) weakSelf = self;
    [YubiKitManager.shared.accessorySession.fido2Service executeMakeCredentialRequest:makeCredentialRequest completion:^(YKFKeyFIDO2MakeCredentialResponse *response, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            [TestSharedLogger.shared logMessage:@"Make Credential request ended in error: %ld - %@.", error.code, error.localizedDescription];
            return;
        }
        
        [TestSharedLogger.shared logMessage:@"Make Credential request successful."];
        [strongSelf logFIDO2MakeCredentialResponse:response];
        
        YKFFIDO2AuthenticatorData *authenticatorData = response.authenticatorData;
        if (authenticatorData) {
            YKFFIDO2PublicKeyCredentialDescriptor *credentialDescriptor = [[YKFFIDO2PublicKeyCredentialDescriptor alloc] init];
            credentialDescriptor.credentialId = authenticatorData.credentialId;
            
            YKFFIDO2PublicKeyCredentialType *credType = [[YKFFIDO2PublicKeyCredentialType alloc] init];
            credType.name = @"public-key";
            credentialDescriptor.credentialType = credType;
            
            getAssertionRequest.allowList = @[credentialDescriptor];
            
            [YubiKitManager.shared.accessorySession.fido2Service executeGetAssertionRequest:getAssertionRequest completion:^(YKFKeyFIDO2GetAssertionResponse * response, NSError *error) {
                if (error) {
                    [TestSharedLogger.shared logMessage:@"Get Assertion request ended in error: %ld - %@.", error.code, error.localizedDescription];
                    return;
                }
                
                [TestSharedLogger.shared logMessage:@"Get Assertion request successful."];
                [strongSelf logFIDO2GetAssertionResponse:response];
            }];
        }
    }];
}

- (void)addFIDO2CredentialWithAlg:(NSInteger)alg options:(NSDictionary *)options {
    YKFKeyFIDO2MakeCredentialRequest *makeCredentialRequest = [[YKFKeyFIDO2MakeCredentialRequest alloc] init];
    
    UInt8 *buffer = malloc(32);
    if (!buffer) {
        return;
    }
    memset(buffer, 0, 32);
    NSData *data = [NSData dataWithBytes:buffer length:32];
    free(buffer);
    
    // client data hash
    makeCredentialRequest.clientDataHash = data;
    
    // RP
    YKFFIDO2PublicKeyCredentialRpEntity *rp = [[YKFFIDO2PublicKeyCredentialRpEntity alloc] init];
    rp.rpId = @"example.com";
    rp.rpName = @"Acme";
    makeCredentialRequest.rp = rp;
    
    // User
    YKFFIDO2PublicKeyCredentialUserEntity *user = [[YKFFIDO2PublicKeyCredentialUserEntity alloc] init];
    user.userId = data;
    user.userName = @"johnpsmith@example.com";
    user.userDisplayName = @"John P. Smith";
    makeCredentialRequest.user = user;
    
    // pubKeyParams
    YKFFIDO2PublicKeyCredentialParam *param = [[YKFFIDO2PublicKeyCredentialParam alloc] init];
    param.alg = alg;
    makeCredentialRequest.pubKeyCredParams = @[param];
    
    // options
    makeCredentialRequest.options = options;
    
    [TestSharedLogger.shared logMessage:@"Requesting FIDO2 authenticatorMakeCredential."];
    
    __weak typeof(self) weakSelf = self;
    [YubiKitManager.shared.accessorySession.fido2Service executeMakeCredentialRequest:makeCredentialRequest completion:^(YKFKeyFIDO2MakeCredentialResponse *response, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            [TestSharedLogger.shared logMessage:@"Make Credential request ended in error: %ld - %@.", error.code, error.localizedDescription];
            return;
        }
        
        [TestSharedLogger.shared logMessage:@"Make Credential request successful."];
        [strongSelf logFIDO2MakeCredentialResponse:response];
    }];
}

#pragma mark - FIDO2 Log Helpers

- (void)logFIDO2GetInfoResponse:(YKFKeyFIDO2GetInfoResponse *)response {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Get Info Response"];
    [TestSharedLogger.shared logSepparator];
    
    [TestSharedLogger.shared logMessage:@"\nVersions"];
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"%@", response.versions.description];
    
    [TestSharedLogger.shared logMessage:@"\nExtensions"];
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"%@", response.extensions.description];
    
    [TestSharedLogger.shared logMessage:@"\nAAGUID"];
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"%@", response.aaguid.description];
    
    [TestSharedLogger.shared logMessage:@"\nOptions"];
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"%@", response.options.description];
    
    [TestSharedLogger.shared logMessage:@"\nMaxMsgSize"];
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"%ld", (long)response.maxMsgSize];
    
    [TestSharedLogger.shared logMessage:@"\nPin Protocols"];
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"%@", response.pinProtocols.description];
}

- (void)logFIDO2MakeCredentialResponse:(YKFKeyFIDO2MakeCredentialResponse *)response {
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Make credential response"];
    [TestSharedLogger.shared logSepparator];
    
    NSData *authData = response.authData;
    [TestSharedLogger.shared logMessage:@"\nAuth Data"];
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"%@", authData.description];
    
    NSString *fmt = response.fmt;
    [TestSharedLogger.shared logMessage:@"\nFmt", fmt];
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"%@", fmt];
    
    NSData *attStmt = response.attStmt;
    [TestSharedLogger.shared logMessage:@"\nAtt stmt"];
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"%@", attStmt.description];
    
    YKFFIDO2AuthenticatorData *authenticatorData = response.authenticatorData;
    if (authenticatorData) {
        [TestSharedLogger.shared logMessage:@"\nParsed Auth Data"];
        [TestSharedLogger.shared logSepparator];
        
        [TestSharedLogger.shared logMessage:@"\nRP ID Hash"];
        [TestSharedLogger.shared logSepparator];
        [TestSharedLogger.shared logMessage:@"%@", authenticatorData.rpIdHash.description];
        
        [TestSharedLogger.shared logMessage:@"\nFlags"];
        [TestSharedLogger.shared logSepparator];
        [TestSharedLogger.shared logMessage:@"%d", authenticatorData.flags];
        
        [TestSharedLogger.shared logMessage:@"\nSignature Count"];
        [TestSharedLogger.shared logSepparator];
        [TestSharedLogger.shared logMessage:@"%d", authenticatorData.signCount];
        
        [TestSharedLogger.shared logMessage:@"\nAAGUID"];
        [TestSharedLogger.shared logSepparator];
        [TestSharedLogger.shared logMessage:@"%@", authenticatorData.aaguid.description];
        
        [TestSharedLogger.shared logMessage:@"\nCredential ID"];
        [TestSharedLogger.shared logSepparator];
        [TestSharedLogger.shared logMessage:@"%@", authenticatorData.credentialId.description];
        
        [TestSharedLogger.shared logMessage:@"\nCose Encoded Public Key"];
        [TestSharedLogger.shared logSepparator];
        [TestSharedLogger.shared logMessage:@"%@", authenticatorData.coseEncodedCredentialPublicKey.description];
    }
}

- (void)logFIDO2GetAssertionResponse:(YKFKeyFIDO2GetAssertionResponse *)response{
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"Get assertion response"];
    [TestSharedLogger.shared logSepparator];

    if (response.credential) {
        [TestSharedLogger.shared logMessage:@"Credential descriptor"];
        [TestSharedLogger.shared logSepparator];
        [TestSharedLogger.shared logMessage:@"ID:\n%@", response.credential.credentialId.description];
        [TestSharedLogger.shared logMessage:@"Type:\n%@", response.credential.credentialType.name];
        [TestSharedLogger.shared logMessage:@"Transports:\n%@", response.credential.credentialTransports.description];
    }
    
    [TestSharedLogger.shared logMessage:@"Auth data"];
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"%@", response.authData];

    [TestSharedLogger.shared logMessage:@"Signature"];
    [TestSharedLogger.shared logSepparator];
    [TestSharedLogger.shared logMessage:@"%@", response.signature];

    if (response.user) {
        [TestSharedLogger.shared logMessage:@"User"];
        [TestSharedLogger.shared logSepparator];
        [TestSharedLogger.shared logMessage:@"ID:\n%@", response.user.userId.description];
        [TestSharedLogger.shared logMessage:@"Name:\n%@", response.user.userName];
        [TestSharedLogger.shared logMessage:@"Display name:\n%@", response.user.userDisplayName];
        [TestSharedLogger.shared logMessage:@"icon:\n%@", response.user.userIcon];
    }

    if (response.numberOfCredentials) {
        [TestSharedLogger.shared logMessage:@"Number of credentials"];
        [TestSharedLogger.shared logSepparator];
        [TestSharedLogger.shared logMessage:@"%ld", (long)response.numberOfCredentials];
    }
}

#pragma mark - Test Helpers

- (BOOL)pingKeyWithData:(NSData *)data length:(NSUInteger)length {
    [TestSharedLogger.shared logMessage:@"Queue ping with data length: %d", length];
    
    YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0 ins:ManualTestsInstructionU2FPing p1:0 p2:0 data:data type:YKFAPDUTypeExtended];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self executeCommandWithAPDU:apdu completion:^(NSData *result, NSError *error) {
        if (error) {
            [TestSharedLogger.shared logError: @"When requesting echo: %@", error.localizedDescription];
            dispatch_semaphore_signal(semaphore);
            return;
        }
        
        [TestSharedLogger.shared logMessage:@"Received data length: %d", result.length];
        
        NSData *echoData = [result subdataWithRange:NSMakeRange(0, result.length - 2)];
        if ([echoData isEqualToData:data]) {
            [TestSharedLogger.shared logSuccess:@"Received data is equal with sent data."];
        } else {
            [TestSharedLogger.shared logError:@"Received data is not equal with sent data."];
        }
        dispatch_semaphore_signal(semaphore);
    }];
    long timeout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC));
    return timeout != 0;
}

- (BOOL)pingKeyWithRandomDataLength:(NSUInteger)length {
    NSUInteger dataLength = length;
    NSData *randomData = [self.testDataGenerator randomDataWithLength:dataLength];
    
    return [self pingKeyWithData:randomData length:dataLength];
}

- (BOOL)pingKeyWithIncrementingDataLength:(NSUInteger)length {
    NSUInteger dataLength = length;
    
    NSMutableData *incrementData = [NSMutableData dataWithCapacity:length];

    for (uint32_t j=0; j<=length; j++) {
        uint8_t byte = j % 0xFF;
        [incrementData appendBytes:&byte length:sizeof(byte)];
    }
    
    return [self pingKeyWithData:incrementData length:dataLength];
}

@end
