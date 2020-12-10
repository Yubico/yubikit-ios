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
#import "NSDate+Utils.h"

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
    
    // Add credential and reset
    NSValue *oathAddCredentialAndResetOATHSelector = [NSValue valueWithPointer:@selector(test_AddCredentialAndResetOATH)];
    NSArray *oathAddCredentialAndResetOATHTestEntry = @[@"OATH Reset", @"Add credential and reset OATH application.", oathAddCredentialAndResetOATHSelector];
    [oathTests addObject:oathAddCredentialAndResetOATHTestEntry];
    
    // Set password and unlock
    NSValue *oathSetCodeAndUnlockSelector = [NSValue valueWithPointer:@selector(test_SetCodeAndUnlock)];
    NSArray *oathSetCodeAndUnlockTestEntry = @[@"OATH set password and unlock", @"Set a password, create new OATH session and unlock.", oathSetCodeAndUnlockSelector];
    [oathTests addObject:oathSetCodeAndUnlockTestEntry];
    
    // Add TOTP credential and calculate
    NSValue *oathAddAndCalculateTOTPSelector = [NSValue valueWithPointer:@selector(test_WhenAddingAnOATHTOTPCredential_CredentialIsAddedToTheKeyAndValueCanBeComputed)];
    NSArray *oathAddAndCalculateTOTPTestEntry = @[@"OATH Put and Calculate TOTP", @"Puts, calculates and removes a TOTP credential.", oathAddAndCalculateTOTPSelector];
    [oathTests addObject:oathAddAndCalculateTOTPTestEntry];
    
    // Add HOTP credential and calculate
    NSValue *oathAddAndCalculateHOTPSelector = [NSValue valueWithPointer:@selector(test_WhenAddingAnOATHHOTPCredential_CredentialIsAddedToTheKeyAndValueCanBeComputed)];
    NSArray *oathAddAndCalculateHOTPTestEntry = @[@"OATH Put and Calculate HOTP", @"Puts, calculates and removes a HOTP credential.", oathAddAndCalculateHOTPSelector];
    [oathTests addObject:oathAddAndCalculateHOTPTestEntry];
    
    // Add credential and rename it
    NSValue *oathAddAndRenameSelector = [NSValue valueWithPointer:@selector(test_WhenRenamingAnOATHCredential_CredentialIsRenamed)];
    NSArray *oathAddAndRenameTestEntry = @[@"OATH Put and Rename", @"Puts, renames and removes a credential.", oathAddAndRenameSelector];
    [oathTests addObject:oathAddAndRenameTestEntry];
    
    //// -------------------------------------------------------------------------------------------------------------------------------------------------------
    //// Challenge/Response tests
    NSMutableArray *chalRespTests = [[NSMutableArray alloc] init];

    // Do hmac challenge response in slot 1, assumes a secret is already programmed
    NSValue *hmacChalSlot1Resp = [NSValue valueWithPointer:@selector(test_WhenSendingChallengeToSlot1_KeySendsHmacResponse)];
    NSArray *hmacChalSlot1RespTestEntry = @[@"HMAC Chal", @"Performs a Challenge/Response.", hmacChalSlot1Resp];
    [chalRespTests addObject:hmacChalSlot1RespTestEntry];

    //// -------------------------------------------------------------------------------------------------------------------------------------------------------
    //// Management tests
    NSMutableArray *mgmtTests = [[NSMutableArray alloc] init];

    NSValue *selector = [NSValue valueWithPointer:@selector(test_WhenDisablingOTPApplicationOverNFCandUSB)];
    NSArray *testEntry = @[@"Management read and write", @"Enables/disables YubiKey interfaces", selector];
    [mgmtTests addObject:testEntry];

    //// -------------------------------------------------------------------------------------------------------------------------------------------------------
    //// PIV tests
    NSMutableArray *pivTests = [[NSMutableArray alloc] init];

    // Do rsa sig
    NSValue *pivGenAuthRsaSig = [NSValue valueWithPointer:@selector(test_generateRsa2048Signature)];
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
                      @[@"Management Tests", mgmtTests],
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
        [TestSharedLogger.shared logSuccess:@"Received application version."];
    }];
}

#pragma mark - OATH Tests

- (void)test_AddCredentialAndResetOATH {
    [self.connection oathSession:^(YKFKeyOATHSession * _Nullable session, NSError * _Nullable sessionError) {
        if (sessionError) {
            [TestSharedLogger.shared logError:@"Could not create OATH session."];
            return;
        }
        NSString *oathUrlString = @"otpauth://totp/Yubico:oath-reset-test@yubico.com?secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=Yubico&algorithm=SHA1&digits=6&period=30";
        NSURL *url = [NSURL URLWithString:oathUrlString];
        YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:url];

        [session putCredentialTemplate:credential requiresTouch:NO completion:^(NSError * _Nullable error) {
            if (error) {
                [TestSharedLogger.shared logError:@"Could not add the credential to the key."];
                return;
            }
            [TestSharedLogger.shared logMessage:@"Credential was added to the key."];
        }];
        
        [session resetWithCompletion:^(NSError * _Nullable error) {
            if (error) {
                [TestSharedLogger.shared logError:@"Could not reset OATH."];
                return;
            }
            [session listCredentialsWithCompletion:^(NSArray<YKFOATHCredential *> * _Nullable credentials, NSError * _Nullable error) {
                if (error) {
                    [TestSharedLogger.shared logError:@"Could not list OATH credentials."];
                    return;
                }
                [TestSharedLogger.shared logMessage:@"Listed %i credentials on key after reset", credentials.count];
                if (credentials.count != 0) {
                    [TestSharedLogger.shared logError:@"Failed to reset OATH credentials. Still %i credentials on key.", credentials.count];
                    return;
                }
                [TestSharedLogger.shared logSuccess:@"Reset OATH."];
            }];
        }];
        
    }];
}

- (void)test_SetCodeAndUnlock {
    [self.connection oathSession:^(id<YKFKeyOATHSessionProtocol> _Nullable session, NSError * _Nullable error) {
        if (error) {
            [TestSharedLogger.shared logError:@"Could not create OATH session: %@", error];
            return;
        }
        [session setPassword:@"271828" completion:^(NSError * _Nullable error) {
            if (error) {
                [TestSharedLogger.shared logError:@"Failed to set code: %@", error];
                return;
            }
            // We need to select a different application and then reselect oath to force the oath session to ask for the new passcode.
            [self.connection fido2Session:^(YKFKeyFIDO2Session * _Nullable fidoSession, NSError * _Nullable error) {
                if (error) {
                    [TestSharedLogger.shared logError:@"Failed to create FIDO2 session: %@", error];
                    return;
                }
                [self.connection oathSession:^(YKFKeyOATHSession * _Nullable session, NSError * _Nullable error) {
                    if (error) {
                        [TestSharedLogger.shared logError:@"Could not create OATH session: %@", error];
                        return;
                    }
                    [session unlockWithPassword:@"271828" completion:^(NSError * _Nullable error) {
                        if (error) {
                            [TestSharedLogger.shared logError:@"Could not unlock OATH session: %@", error];
                            return;
                        }
                        [session listCredentialsWithCompletion:^(NSArray<YKFOATHCredential *> * _Nullable credentials, NSError * _Nullable error) {
                            if (error) {
                                [TestSharedLogger.shared logError:@"Could not list credentials after successful unlock: %@", error];
                                return;
                            }
                            [session setPassword:@"" completion:^(NSError * _Nullable error) {
                                if (error) {
                                    [TestSharedLogger.shared logError:@"Failed to remove password: %@", error];
                                    return;
                                }
                                [TestSharedLogger.shared logSuccess:@"Set password and unlock."];
                            }];
                        }];
                    }];
                }];
            }];
        }];
    }];
}

- (void)test_WhenAddingAnOATHTOTPCredential_CredentialIsAddedToTheKeyAndValueCanBeComputed {
    // This is an URL conforming to Key URI Format specs.
    NSString *oathUrlString = @"otpauth://totp/Yubico:oath-add-totp-test@yubico.com?secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=Yubico&algorithm=SHA1&digits=6&period=30";
    NSURL *url = [NSURL URLWithString:oathUrlString];
    if (!url) {
        [TestSharedLogger.shared logError:@"Invalid OATH URL."];
        return;
    }
    
    // Create the credential from the URL using the convenience initializer.
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:url];
    if (!credential) {
        [TestSharedLogger.shared logError:@"Could not create OATH credential."];
        return;
    }
    
    [self.connection oathSession:^(id<YKFKeyOATHSessionProtocol> _Nullable session, NSError * _Nullable sessionError) {
        if (sessionError) {
            [TestSharedLogger.shared logError:@"Could not create OATH session."];
            return;
        }
        /*
         1. Add the credential to the key
         */
        [session putCredentialTemplate:credential requiresTouch:NO completion:^(NSError * _Nullable error) {
            if (error) {
                [TestSharedLogger.shared logError:@"Could not add the credential to the key."];
                return;
            }
            [TestSharedLogger.shared logSuccess:@"The credential was added to the key."];
        }];
        
        /*
         2. List credentials.
         */
        [session listCredentialsWithCompletion:^(NSArray<YKFOATHCredential *> * _Nullable credentials, NSError * _Nullable error) {
            YKFOATHCredential *newCredential;
            for(YKFOATHCredential *credential in credentials) {
                if ([credential.accountName isEqual:@"oath-add-totp-test@yubico.com"]) {
                    newCredential = credential;
                }
            }
            if (error || !newCredential) {
                [TestSharedLogger.shared logError:@"Could not read credential from the key."];
                return;
            }
            /*
             2. Swizzle [NSDate date] to always return the same date and calculate TOTP using calculate and calculate all
             */
            [NSDate swizzleDate];

            [session calculateCredential:newCredential completion:^(YKFOATHCode * _Nullable response, NSError * _Nullable error) {
                if (error || ![response.otp isEqualToString:@"239396"]) {
                    [TestSharedLogger.shared logError:@"Could not calculate the credential using calculate."];
                    return;
                }
                NSString *successLog = [NSString stringWithFormat:@"OTP value for the credential %@ is %@", credential.accountName, response.otp];
                [TestSharedLogger.shared logSuccess:successLog];
            }];
            
            [session calculateAllWithCompletion:^(NSArray<YKFOATHCredentialWithCode *> * _Nullable credentials, NSError * _Nullable error) {
                if (error) {
                    [TestSharedLogger.shared logError:@"Could not calculate the credential."];
                    return;
                }
                YKFOATHCredentialWithCode *credentialWithCode;
                for(YKFOATHCredentialWithCode *result in credentials) {
                    if ([result.credential.accountName isEqual:@"oath-add-totp-test@yubico.com"]) {
                        credentialWithCode = result;
                    }
                }
                if (![credentialWithCode.code.otp isEqualToString:@"239396"]) {
                    [TestSharedLogger.shared logError:@"Could not calculate the credential using calculate all."];
                    return;
                }
                NSString *successLog = [NSString stringWithFormat:@"OTP value for the credential %@ is %@", credentialWithCode.credential.accountName, credentialWithCode.code.otp];
                [TestSharedLogger.shared logSuccess:successLog];
            }];
            
            /*
             3. Remove the credential.
             */
            [session deleteCredential:newCredential completion:^(NSError * _Nullable error) {
                [NSDate swizzleDate];
                if (error) {
                    [TestSharedLogger.shared logError:@"Could not delete the credential."];
                    return;
                }
                [TestSharedLogger.shared logSuccess:@"The credential was removed from the key."];
            }];
        }];
    }];
}

- (void)test_WhenAddingAnOATHHOTPCredential_CredentialIsAddedToTheKeyAndValueCanBeComputed {
    NSString *oathUrlString = @"otpauth://hotp/Yubico:oath-add-hotp-test@yubico.com?secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=Yubico&algorithm=SHA1&digits=6&counter=30";
    NSURL *url = [NSURL URLWithString:oathUrlString];
    if (!url) {
        [TestSharedLogger.shared logError:@"Invalid OATH URL."];
        return;
    }
    
    // Create the credential from the URL using the convenience initializer.
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:url];
    if (!credential) {
        [TestSharedLogger.shared logError:@"Could not create OATH credential."];
        return;
    }
    
    [self.connection oathSession:^(id<YKFKeyOATHSessionProtocol> _Nullable session, NSError * _Nullable sessionError) {
        if (sessionError) {
            [TestSharedLogger.shared logError:@"Could not create OATH session."];
            return;
        }
        /*
         1. Add the credential to the key
         */
        [session putCredentialTemplate:credential requiresTouch:NO completion:^(NSError * _Nullable error) {
            if (error) {
                [TestSharedLogger.shared logError:@"Could not add the credential to the key."];
                return;
            }
            [TestSharedLogger.shared logSuccess:@"The credential was added to the key."];
        }];
        
        /*
         2. List credentials.
         */
        [session listCredentialsWithCompletion:^(NSArray<YKFOATHCredential *> * _Nullable credentials, NSError * _Nullable error) {
            YKFOATHCredential *newCredential;
            for(YKFOATHCredential *credential in credentials) {
                if ([credential.accountName isEqual:@"oath-add-hotp-test@yubico.com"]) {
                    newCredential = credential;
                }
            }
            if (error || !newCredential) {
                [TestSharedLogger.shared logError:@"Could not read credential from the key."];
                return;
            }
            /*
             2. Calculate HOTP
             */
            [session calculateCredential:newCredential completion:^(YKFOATHCode * _Nullable response, NSError * _Nullable error) {
                if (error || ![response.otp isEqualToString:@"726826"]) {
                    [TestSharedLogger.shared logError:@"Could not calculate the credential using calculate."];
                    return;
                }
                NSString *successLog = [NSString stringWithFormat:@"OTP value for the credential %@ is %@", credential.accountName, response.otp];
                [TestSharedLogger.shared logSuccess:successLog];
            }];
            
            /*
             3. Remove the credential.
             */
            [session deleteCredential:newCredential completion:^(NSError * _Nullable error) {
                if (error) {
                    [TestSharedLogger.shared logError:@"Could not delete the credential."];
                    return;
                }
                [TestSharedLogger.shared logSuccess:@"The credential was removed from the key."];
            }];
        }];
    }];
}


- (void)test_WhenRenamingAnOATHCredential_CredentialIsRenamed {
    // This is an URL conforming to Key URI Format specs.
    NSString *oathUrlString = @"otpauth://totp/Yubico:oath-rename-test@yubico.com?secret=UOA6FJYR76R7IRZBGDJKLYICL3MUR7QH&issuer=Yubico&algorithm=SHA1&digits=6&period=30";
    NSURL *url = [NSURL URLWithString:oathUrlString];
    if (!url) {
        [TestSharedLogger.shared logError:@"Invalid OATH URL."];
        return;
    }
    
    // Create the credential from the URL using the convenience initializer.
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:url];
    if (!credential) {
        [TestSharedLogger.shared logError:@"Could not create OATH credential."];
        return;
    }
    
    [self.connection oathSession:^(id<YKFKeyOATHSessionProtocol> _Nullable session, NSError * _Nullable sessionError) {
        if (sessionError) {
            [TestSharedLogger.shared logError:@"Could not create OATH session."];
            return;
        }
        /*
         1. Add the credential to the key
         */
        [session putCredentialTemplate:credential requiresTouch:NO completion:^(NSError * _Nullable error) {
            if (error) {
                [TestSharedLogger.shared logError:@"Could not add the credential to the key."];
                return;
            }
            [TestSharedLogger.shared logSuccess:@"The credential was added to the key."];
        }];
        
        /*
         2. Rename the credential.
         */
        [session listCredentialsWithCompletion:^(NSArray<YKFOATHCredential *> * _Nullable credentials, NSError * _Nullable error) {
            YKFOATHCredential *newCredential;
            for(YKFOATHCredential *credential in credentials) {
                if ([credential.accountName isEqual:@"oath-rename-test@yubico.com"]) {
                    newCredential = credential;
                }
            }
            if (error || !newCredential) {
                [TestSharedLogger.shared logError:@"Could not read credential from the key."];
                return;
            }
            
            [session renameCredential:newCredential newIssuer:@"Transnomino Inc" newAccount:@"renamed-account@yubico.com" completion:^(NSError * _Nullable error) {
                if (error) {
                    [TestSharedLogger.shared logError:@"Could not rename the credential. %@", error];
                    return;
                }
                [TestSharedLogger.shared logSuccess:@"Credential renamed"];
            }];
            
            /*
             3. List credentials and verify that the credential has been renamed
             */
            [session listCredentialsWithCompletion:^(NSArray<YKFOATHCredential*> * _Nullable credentials, NSError * _Nullable error) {
                if (error) {
                    [TestSharedLogger.shared logError:@"Could not list credentials. %@", error];
                }
                
                YKFOATHCredential* renamedCredential;
                for (YKFOATHCredential* credential in credentials) {
                    if ([credential.issuer isEqual:@"Transnomino Inc"] && [credential.accountName isEqual:@"renamed-account@yubico.com"]) {
                        renamedCredential = credential;
                        break;
                    }
                }
                
                if (renamedCredential) {
                    [TestSharedLogger.shared logSuccess:@"Retrieved and verified renamed credential from key"];
                    
                    [session deleteCredential:renamedCredential completion:^(NSError * _Nullable error) {
                        if (error) {
                            [TestSharedLogger.shared logError:@"Could not delete the credential. %@", error];
                            return;
                        }
                        [TestSharedLogger.shared logSuccess:@"The credential was removed from the key."];
                    }];
                    
                } else {
                    [session deleteCredential:newCredential completion:^(NSError * _Nullable error) {
                        if (error) {
                            [TestSharedLogger.shared logError:@"Could not delete the credential. %@", error];
                            return;
                        }
                        [TestSharedLogger.shared logSuccess:@"The credential was removed from the key."];
                    }];
                    [TestSharedLogger.shared logError:@"Failed retrieving renamed credential"];
                }
            }];
        }];
    }];
}

#pragma mark - Challenge/Response Tests

// HMAC-SHA1 with f6d6475b48b94f0d849a6c19bf8cc7f0d62255a0 as a secret
// Challenge/Response: challenge/0e2df6bacc23764aeb3d9792ed17b063c7d254fa

- (void)test_WhenSendingChallengeToSlot1_KeySendsHmacResponse {
    NSString *hexString = @"313233343536";
    NSData *data = [self.testDataGenerator dataFromHexString:hexString];
    [TestSharedLogger.shared logMessage:@"Challenge data:\n%@", data];

    [TestSharedLogger.shared logMessage:@"Using YKFKeyChallengeResponseService"];
    
    [self.connection challengeResponseSession:^(YKFKeyChallengeResponseSession * _Nullable session, NSError * _Nullable error) {

        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        [session sendChallenge:data slot:YKFSlotOne completion:^(NSData *result, NSError *error) {
            if (error) {
                [TestSharedLogger.shared logError: @"When requesting challenge: %@", error.localizedDescription];
                dispatch_semaphore_signal(semaphore);
                return;
            }
            [TestSharedLogger.shared logMessage:@"Received data length: %d", result.length];

            [TestSharedLogger.shared logMessage:@"Response data:\n%@", result];
            dispatch_semaphore_signal(semaphore);
        }];
        
        // waiting until completed before starting another test
        long timeout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 20 * NSEC_PER_SEC));
        if (timeout) {
            [TestSharedLogger.shared logMessage:@"Failed with timeout"];
        }

        [self executeYubiKeyApplicationSelection];

        // another method of doing challenge response without YKFKeyChallengeResponseService
        YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0 ins:0x01 p1:0x30 p2:0 data:data type:YKFAPDUTypeShort];

        [TestSharedLogger.shared logSepparator];
        [TestSharedLogger.shared logMessage:@"Using YKFKeyRawCommandService"];

        [self executeCommandWithAPDU:apdu completion:^(NSData *result, NSError *error) {
            if (error) {
                [TestSharedLogger.shared logError: @"When requesting challenge: %@", error.localizedDescription];
                return;
            }
            [TestSharedLogger.shared logMessage:@"Received data length: %d", result.length];

            NSData *respData = [result subdataWithRange:NSMakeRange(0, result.length - 2)];
            [TestSharedLogger.shared logMessage:@"Response data:\n%@", respData];
        }];
    }];
}

#pragma mark Management (management) Tests

- (void) test_WhenDisablingOTPApplicationOverNFCandUSB {
    [self.connection managementSession:^(YKFKeyManagementSession * _Nullable session, NSError * _Nullable error) {
        [session readConfigurationWithCompletion:^(YKFKeyManagementReadConfigurationResponse *selectionResponse, NSError *error) {
            if (error) {
                [TestSharedLogger.shared logError: @"When reading configurations: %@", error.localizedDescription];
                return;
            }
            YKFManagementInterfaceConfiguration *configuration = selectionResponse.configuration;
            
            YKFManagementTransportType transport = YKFManagementTransportTypeNFC;
            if(![configuration isSupported:YKFManagementApplicationTypeOTP overTransport:transport]) {
                [TestSharedLogger.shared logMessage:@"OTP over NFC is not supported"];
                transport = YKFManagementTransportTypeUSB;
            }
            
            BOOL isOTPenabled = [configuration isEnabled:YKFManagementApplicationTypeOTP overTransport:transport];
            if (isOTPenabled) {
                [TestSharedLogger.shared logMessage:@"OTP is enabled"];
            } else {
                [TestSharedLogger.shared logMessage:@"OTP is disabled"];
            }

            [configuration setEnabled:!isOTPenabled application:YKFManagementApplicationTypeOTP overTransport:transport];
            
            [TestSharedLogger.shared logMessage:@"Updating configuration"];
            [session writeConfiguration:configuration reboot:NO completion:^(NSError * _Nullable error) {
                if (error) {
                    [TestSharedLogger.shared logError: @"When writing configurations: %@", error.localizedDescription];
                    return;
                }
                
                [TestSharedLogger.shared logMessage:@"Configuration has been updated."];

                [session readConfigurationWithCompletion:^(YKFKeyManagementReadConfigurationResponse *selectionResponse, NSError *error) {
                    if (error) {
                        [TestSharedLogger.shared logError: @"When reading configurations: %@", error.localizedDescription];
                        return;
                    }
                    YKFManagementInterfaceConfiguration *configuration = selectionResponse.configuration;

                    BOOL isOTPenabled = [configuration isEnabled:YKFManagementApplicationTypeOTP overTransport:transport];
                    if (isOTPenabled) {
                        [TestSharedLogger.shared logMessage:@"OTP is enabled"];
                    } else {
                        [TestSharedLogger.shared logMessage:@"OTP is disabled"];
                    }
                }];
            }];
        }];
    }];
}

#pragma mark - Piv Tests

- (void)test_generateRsa2048Signature {
    [self executePivApplicationSelection];
    // Verify PIN with default PIN number (123456)
    NSData *pinData = [NSData dataWithBytes:(UInt8[]){0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0xff, 0xff} length:8];
    YKFAPDU *pinApdu = [[YKFAPDU alloc] initWithCla:0x00 ins:0x20 p1:0x00 p2:0x80 data:pinData type:YKFAPDUTypeShort];
    [self executeCommandWithAPDU:pinApdu completion:^(NSData *result, NSError *error) {
        if (error) {
            [TestSharedLogger.shared logError: @"Failed pin verification: %@", error.localizedDescription];
            return;
        }
        [TestSharedLogger.shared logMessage:@"PIN verified."];
        NSData *data = [self.testDataGenerator dataFromHexString:@"7c8201068200818201000001ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff003031300d060960864801650304020105000420c6b7edaa05038235152a79711e34f64e0d0b01e5c3952cb588b3dbbf0d23009400"];
        YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0x00 ins:0x87 p1:0x07 p2:0x9a data:data type:YKFAPDUTypeExtended];
        [self executeCommandWithAPDU:apdu completion:^(NSData * _Nullable resultData, NSError * _Nullable error) {
            if (error) {
                [TestSharedLogger.shared logError: @"Make sure there is a RSA2048 certificate in slot 9a on your Yubikey. Error: %d", error.code];
                return;
            }
            [TestSharedLogger.shared logMessage:@"Sent data: %@", data];
            [TestSharedLogger.shared logMessage:@"Received data: %@", resultData];
            [TestSharedLogger.shared logSuccess:@"RSA2048 decrypt successfull"];
        }];
    }];
}

#pragma mark - FIDO2 Tests

- (void)test_WhenCallingFIDO2Reset_KeyApplicationResets {
    [self.connection fido2Session:^(id<YKFKeyFIDO2SessionProtocol> _Nullable session, NSError * _Nullable sessionError) {
        if (sessionError) {
            [TestSharedLogger.shared logMessage:@"Failed to create FIDO2 session: %ld - %@", sessionError.code, sessionError.localizedDescription];
            return;
        }
        
        [session resetWithCompletion:^(NSError * _Nullable error) {
            if (error) {
                [TestSharedLogger.shared logMessage:@"Reset request ended in error: %ld - %@.", error.code, error.localizedDescription];
                return;
            }
            [TestSharedLogger.shared logMessage:@"Reset request successful."];
        }];
    }];
}

- (void)test_WhenCallingFIDO2GetInfo_TheKeyReturnsAutheticatorProperties {
    __weak typeof(self) weakSelf = self;
    YKFAccessoryConnection *session = YubiKitManager.shared.accessorySession;
    [session fido2Session:^(id<YKFKeyFIDO2SessionProtocol> _Nullable session, NSError * _Nullable sessionError) {
        if (sessionError) {
            [TestSharedLogger.shared logMessage:@"Failed to create FIDO2 session: %ld - %@", sessionError.code, sessionError.localizedDescription];
            return;
        }
        
        [session getInfoWithCompletion:^(YKFKeyFIDO2GetInfoResponse *response, NSError *error) {
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
    }];
}

- (void)test_WhenAdingFIDO2Credential_ECCNonRKCredentialIsAddedToTheKey {
    NSDictionary *makeCredentialOptions = @{YKFKeyFIDO2OptionRK: @(NO)};
    
    [self addFIDO2CredentialWithAlg:YKFFIDO2PublicKeyAlgorithmES256 options:makeCredentialOptions];
}

- (void)test_WhenAdingFIDO2Credential_EdDSACredentialIsAddedToTheKey {
    NSDictionary *makeCredentialOptions = @{YKFKeyFIDO2OptionRK: @(NO)};
    
    [self addFIDO2CredentialWithAlg:YKFFIDO2PublicKeyAlgorithmEdDSA options:makeCredentialOptions];
}

- (void)test_AfterAdingECCFIDO2Credential_SignatureCanBeRequested {
    NSDictionary *makeCredentialOptions = @{YKFKeyFIDO2OptionRK: @(NO)};
    NSDictionary *getAssertionOptions = @{YKFKeyFIDO2OptionUP: @(YES),
                                          YKFKeyFIDO2OptionUV: @(NO)};
    
    [self addFIDO2CredentialWithAlg:YKFFIDO2PublicKeyAlgorithmES256 options:makeCredentialOptions getAssertionOptions:getAssertionOptions];
}

- (void)test_AfterAdingEdDSAFIDO2Credential_SignatureCanBeRequested {
    NSDictionary *makeCredentialOptions = @{YKFKeyFIDO2OptionRK: @(YES)};
    NSDictionary *getAssertionOptions = @{YKFKeyFIDO2OptionUP: @(YES),
                                          YKFKeyFIDO2OptionUV: @(NO)};
    
    [self addFIDO2CredentialWithAlg:YKFFIDO2PublicKeyAlgorithmEdDSA options:makeCredentialOptions getAssertionOptions:getAssertionOptions];
}

- (void)test_AfterAdingECCFIDO2Credential_SilentSignatureCanBeRequested {
    NSDictionary *makeCredentialOptions = @{YKFKeyFIDO2OptionRK: @(NO)};
    NSDictionary *getAssertionOptions = @{YKFKeyFIDO2OptionUP: @(NO),
                                          YKFKeyFIDO2OptionUV: @(NO)};
    
    [self addFIDO2CredentialWithAlg:YKFFIDO2PublicKeyAlgorithmES256 options:makeCredentialOptions getAssertionOptions:getAssertionOptions];
}

#pragma mark - Touch Tests

- (void)test_WhenTouchIsRequiredForCCID_TouchIsDetected {
    YKFAPDU *selectApplicationAPDU = [[YKFSelectApplicationAPDU alloc] initWithApplicationName:YKFSelectApplicationAPDUNameManagement];
    __weak typeof(self) weakSelf = self;
    [self executeCommandWithAPDU:selectApplicationAPDU completion:^(NSData *response, NSError *error) {
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
    
    UInt8 *buffer = malloc(32);
    if (!buffer) {
        return;
    }
    memset(buffer, 0, 32);
    NSData *data = [NSData dataWithBytes:buffer length:32];
    free(buffer);
    
    // Make Credential Request Params
    NSData *clientDataHash = data;
    
    YKFFIDO2PublicKeyCredentialRpEntity *rp = [[YKFFIDO2PublicKeyCredentialRpEntity alloc] init];
    rp.rpId = @"example.com";
    rp.rpName = @"Acme";
    
    YKFFIDO2PublicKeyCredentialUserEntity *user = [[YKFFIDO2PublicKeyCredentialUserEntity alloc] init];
    user.userId = data;
    user.userName = @"johnpsmith@example.com";
    user.userDisplayName = @"John P. Smith";
    
    YKFFIDO2PublicKeyCredentialParam *param = [[YKFFIDO2PublicKeyCredentialParam alloc] init];
    param.alg = alg;
    NSArray  *pubKeyCredParams = @[param];
    
    __weak typeof(self) weakSelf = self;
    
    YKFAccessoryConnection *connection = YubiKitManager.shared.accessorySession;
    
    [connection fido2Session:^(id<YKFKeyFIDO2SessionProtocol> _Nullable session, NSError * _Nullable sessionError) {
        if (sessionError) {
            [TestSharedLogger.shared logMessage:@"Failed to create FIDO2 session: %ld - %@", sessionError.code, sessionError.localizedDescription];
            return;
        }
        
        [session makeCredentialWithClientDataHash:clientDataHash rp:rp user:user pubKeyCredParams:pubKeyCredParams excludeList:nil options:options completion:^(YKFKeyFIDO2MakeCredentialResponse * _Nullable response, NSError * _Nullable error) {
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
                
                NSArray *allowList = @[credentialDescriptor];
                NSString *rpId = @"example.com";
                
                [session getAssertionWithClientDataHash:clientDataHash rpId:rpId allowList:allowList options:assertionOptions completion:^(YKFKeyFIDO2GetAssertionResponse * _Nullable response, NSError * _Nullable error) {
                    if (error) {
                        [TestSharedLogger.shared logMessage:@"Get Assertion request ended in error: %ld - %@.", error.code, error.localizedDescription];
                        return;
                    }
                    
                    [TestSharedLogger.shared logMessage:@"Get Assertion request successful."];
                    [strongSelf logFIDO2GetAssertionResponse:response];
                }];
            }
        }];
    }];
}

- (void)addFIDO2CredentialWithAlg:(NSInteger)alg options:(NSDictionary *)options {
//    YKFKeyFIDO2MakeCredentialRequest *makeCredentialRequest = [[YKFKeyFIDO2MakeCredentialRequest alloc] init];
    
    UInt8 *buffer = malloc(32);
    if (!buffer) {
        return;
    }
    memset(buffer, 0, 32);
    NSData *data = [NSData dataWithBytes:buffer length:32];
    free(buffer);
    
    // client data hash
    NSData *clientDataHash = data;
    
    // RP
    YKFFIDO2PublicKeyCredentialRpEntity *rp = [[YKFFIDO2PublicKeyCredentialRpEntity alloc] init];
    rp.rpId = @"example.com";
    rp.rpName = @"Acme";
    
    // User
    YKFFIDO2PublicKeyCredentialUserEntity *user = [[YKFFIDO2PublicKeyCredentialUserEntity alloc] init];
    user.userId = data;
    user.userName = @"johnpsmith@example.com";
    user.userDisplayName = @"John P. Smith";
    
    // pubKeyParams
    YKFFIDO2PublicKeyCredentialParam *param = [[YKFFIDO2PublicKeyCredentialParam alloc] init];
    param.alg = alg;
    NSArray *pubKeyCredParams = @[param];
    
    [TestSharedLogger.shared logMessage:@"Requesting FIDO2 authenticatorMakeCredential."];
    
    __weak typeof(self) weakSelf = self;
    YKFAccessoryConnection *connection = YubiKitManager.shared.accessorySession;
    
    [connection fido2Session:^(id<YKFKeyFIDO2SessionProtocol> _Nullable session, NSError * _Nullable sessionError) {
        if (sessionError) {
            [TestSharedLogger.shared logMessage:@"Failed to create FIDO2 session: %ld - %@", sessionError.code, sessionError.localizedDescription];
            return;
        }
        [session makeCredentialWithClientDataHash:clientDataHash rp:rp user:user pubKeyCredParams:pubKeyCredParams excludeList:nil options:options completion:^(YKFKeyFIDO2MakeCredentialResponse * _Nullable response, NSError * _Nullable error) {
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
        
        if ([result isEqualToData:result]) {
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
