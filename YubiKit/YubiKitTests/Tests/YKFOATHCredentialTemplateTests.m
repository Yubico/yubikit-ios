// Copyright 2018-2019 Yubico AB
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

#import <XCTest/XCTest.h>

#import "YKFNSStringAdditions.h"
#import "YKFTestCase.h"
#import "YKFOATHCredentialTemplate.h"
#import "YKFOATHCredential.h"
#import "YKFOATHCredential+Private.h"
#import "YKFNSDataAdditions.h"

static NSString* const YKFOATHCredentialValidatorTestsVeryLargeSecret = @"HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZHXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZHXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZHXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZHXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZHXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ";

@interface YKFOATHCredential (TestHelpers)

+ (YKFOATHCredential *)credentialFromTemplate:(YKFOATHCredentialTemplate *)template;

@end

@implementation YKFOATHCredential (TestHelpers)

+ (YKFOATHCredential *)credentialFromTemplate:(YKFOATHCredentialTemplate *)template {
    YKFOATHCredential *credential = [YKFOATHCredential new];
    credential.accountName = template.accountName;
    credential.issuer = template.issuer;
    credential.type = template.type;
    credential.period = template.period;
    return credential;
}

@end

@interface YKFOATHCredentialTests : XCTestCase
@end

@implementation YKFOATHCredentialTests

- (void)test_WhenCredentialIsCreatedWithValidTOTPURL_CredentialIsNotNil {
    NSString *url = @"otpauth://totp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6&period=30";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    XCTAssertNotNil(credential, @"Valid TOTP url was not parsed correctly");
}

- (void)test_WhenCredentialIsCreatedWithValidHOTPURL_CredentialIsNotNil {
    NSString *url = @"otpauth://hotp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6&counter=1234";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    XCTAssertNotNil(credential, @"Valid HOTP url was not parsed correctly");
}

- (void)test_WhenCredentialIsCreatedWithHOTPURL_CredentialTypeIsHOTP {
    NSString *url = @"otpauth://hotp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6&counter=1234";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    XCTAssert(credential.type == YKFOATHCredentialTypeHOTP, @"Credential type incorrectly detected.");
}

- (void)test_WhenCredentialIsCreatedWithHOTPURLWithoutCounter_CredentialIsNil {
    NSString *url = @"otpauth://hotp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6";
    NSError *error = nil;
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url] error:&error];
    XCTAssertNil(credential, @"HOTP credential is not nil when counter is missing.");
    XCTAssert(error.code == 4);
}

- (void)test_WhenCredentialIsCreatedWithValidHOTPURL_PeriodIsZero {
    NSString *url = @"otpauth://hotp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6&counter=1234";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    XCTAssert(credential.period == 0, @"HOTP credential has a validity period.");
}

- (void)test_WhenCredentialIsCreatedWithHOTPURL_DefaultNameIsLabel {
    NSString *url = @"otpauth://hotp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6&counter=123";
    YKFOATHCredentialTemplate *template = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    YKFOATHCredential *credential = [YKFOATHCredential credentialFromTemplate: template];
    XCTAssert([credential.key isEqualToString:credential.label], @"Credential key not correctly generated");
}

- (void)test_WhenCredentialIsCreatedWithTOTPURL_CredentialParametersAreCorrectlyParsed {
    NSString *url = @"otpauth://totp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6&period=40";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    
    XCTAssert(credential.type == YKFOATHCredentialTypeTOTP, @"");
    XCTAssert(credential.algorithm == YKFOATHCredentialAlgorithmSHA1, @"");
    XCTAssert([credential.issuer isEqualToString:@"ACME"], @"");
    XCTAssertNotNil(credential.secret, @"");
    XCTAssert(credential.digits == 6, @"");
    XCTAssert(credential.period == 40, @"");
}

- (void)test_WhenCredentialIsCreatedWithTOTPURL_CredentialTypeIsTOTP {
    NSString *url = @"otpauth://totp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6&period=30";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    XCTAssert(credential.type == YKFOATHCredentialTypeTOTP, @"Credential type incorrectly detected.");
}

- (void)test_WhenCredentialIsCreatedWithTOTPURLWithoutPeriod_CredentialPeriodIsDefault {
    NSString *url = @"otpauth://totp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    XCTAssert(credential.period == 30, @"Credential period is not default.");
}

- (void)test_WhenCredentialIsCreatedWithTOTPURL_NameDoesNotContainThePeriodWhenDefault {
    NSString *url = @"otpauth://totp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6&period=30";
    YKFOATHCredentialTemplate *template = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    YKFOATHCredential *credential = [YKFOATHCredential credentialFromTemplate:template];
    NSString *credentialName = credential.label;
    XCTAssert([credential.key isEqualToString:credentialName], @"Credential key not correctly generated");
}

- (void)test_WhenCredentialIsCreatedWithTOTPURL_NameContainsThePeriodWhenNotDefault {
    NSString *url = @"otpauth://totp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6&period=40";
    YKFOATHCredentialTemplate *template = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    YKFOATHCredential *credential = [YKFOATHCredential credentialFromTemplate:template];
    NSString *credentialName = [NSString stringWithFormat:@"%ld/%@", credential.period, credential.label];
    XCTAssert([credential.key isEqualToString:credentialName], @"Credential key not correctly generated");
}

- (void)test_WhenCredentialIsCreatedWithTOTPURL_SmallerThanDefaultPeriodsAreAccepted {
    NSString *url = @"otpauth://totp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6&period=20";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    
    XCTAssert(credential.period == 20, @"Credential period not correctly parsed.");
}

- (void)test_WhenCredentialIsCreatedWithTOTPURL_PeriodIsDefaultIfNotProvided {
    NSString *url = @"otpauth://totp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    
    XCTAssert(credential.period == 30, @"Default period was not correctly set.");
}

- (void)test_WhenCredentialIsCreatedWithURLWithoutIssuerInURLParam_IssuerIsParsedFromTheLabel {
    NSString *url = @"otpauth://totp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&digits=6&period=30";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    XCTAssert([credential.issuer isEqualToString:@"ACME"], @"Credential is missing the issuer.");
}

- (void)test_WhenCredentialIsCreatedWithURLWithIssuerInURLParamButNotInLabel_IssuerIsParsedFromTheURLl {
    NSString *url = @"otpauth://totp/john@example.com?issuer=ACME&secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&digits=6&period=30";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    XCTAssert([credential.issuer isEqualToString:@"ACME"], @"Credential is missing the issuer.");
}

- (void)test_WhenCredentialIsCreatedWithURLWithoutIssuer_CredentialCanBeCreated {
    NSString *url = @"otpauth://totp/john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&digits=6&period=30";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    XCTAssertNil(credential.issuer, @"Issuer is not nil when key URI does not contain an issuer.");
}

- (void)test_WhenCredentialIsCreatedWithURLWithAnotherIssuerInURLParam_IssuerIsParsedFromPath {
    NSString *url = @"otpauth://totp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&digits=6&period=30&issuer=Ignored";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    XCTAssert([credential.issuer isEqualToString:@"ACME"], @"Credential is missing the issuer.");
}

- (void)test_WhenCredentialIsManuallyCreatedWithoutLabel_LabelIsBuildFromTheIssuerAndAccount {
    YKFOATHCredentialTemplate *template = [[YKFOATHCredentialTemplate alloc] init];
    NSString *label = @"issuer:account";
    YKFOATHCredential *credential = [YKFOATHCredential credentialFromTemplate:template];
    credential.issuer = @"issuer";
    credential.accountName = @"account";
    
    XCTAssert([credential.label isEqualToString:label], @"Credential label is not built if missing.");
}

- (void)test_WhenCredentialIsManuallyCreatedWithoutLabelAndIssuer_LabelIsBuildFromTheAccount {
    YKFOATHCredential *credential = [[YKFOATHCredential alloc] init];
    credential.accountName = @"account";
    
    XCTAssert([credential.label isEqualToString:credential.accountName], @"Credential label is not built if missing.");
}

- (void)test_WhenCredentialIsCreatedWithHOTPURL_KeyIsTheLabel {
    NSString *url = @"otpauth://hotp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&digits=6&counter=0";
    YKFOATHCredentialTemplate *template = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    YKFOATHCredential *credential = [YKFOATHCredential credentialFromTemplate:template];

    XCTAssert([credential.key isEqualToString:credential.label], @"Credential key for HOTP is not the label.");
}

- (void)test_WhenCredentialIsCreatedWithTOTPURLWithDefaultPeriod_KeyIsTheLabel {
    NSString *url = @"otpauth://totp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&digits=6";
    YKFOATHCredentialTemplate *template = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    YKFOATHCredential *credential = [YKFOATHCredential credentialFromTemplate:template];
    
    XCTAssert([credential.key isEqualToString:credential.label], @"Credential key for HOTP is not the label.");
}

- (void)test_WhenCredentialIsCreatedWithTOTPURLWithCustomPeriodAndIssuer_KeyContainsThePeriod {
    NSString *url = @"otpauth://totp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&digits=6&period=15";
    YKFOATHCredentialTemplate *template = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    YKFOATHCredential *credential = [YKFOATHCredential credentialFromTemplate:template];
    NSString *expectedKey = [NSString stringWithFormat:@"%d/%@", 15, credential.label];
    XCTAssert([credential.key isEqualToString:expectedKey], @"Credential key for TOTP with custom period does not contain the period.");
}

- (void)test_WhenCredentialIsCreatedWithTOTPURLWithCustomPeriod_KeyContainsThePeriod {
    NSString *url = @"otpauth://totp/john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&digits=6&period=15";
    YKFOATHCredentialTemplate *template = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    YKFOATHCredential *credential = [YKFOATHCredential credentialFromTemplate:template];
    NSString *expectedKey = [NSString stringWithFormat:@"%d/%@", 15, credential.label];
    XCTAssert([credential.key isEqualToString:expectedKey], @"Credential key for TOTP with custom period does not contain the period.");
}

- (void)test_WhenCredentialIsCreatedWithURLWith7DigitsLength_CredentialParametersAreCorrectlyParsed {
    NSString *url = @"otpauth://totp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=7&period=40";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    XCTAssert(credential.digits == 7, @"");
}
- (void)test_WhenCredentialIsCreatedWithURLWith8DigitsLength_CredentialParametersAreCorrectlyParsed {
    NSString *url = @"otpauth://totp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=8&period=40";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    XCTAssert(credential.digits == 8, @"");
}

- (void)test_WhenCredentialIsCreatedWithURLWithInvalidDigitsLength_CredentialIsNil {
    NSString *url = @"otpauth://totp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=10&period=40";
    NSError *error = nil;
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url] error:&error];
    XCTAssertNil(credential, @"Credential with invalid digits secret is not nil.");
    XCTAssert(error.code == 5);
}

- (void)test_WhenCredentialIsCreatedWithURLWithMissingSecret_CredentialIsNil {
    NSString *url = @"otpauth://totp/ACME:john@example.com?issuer=ACME&algorithm=SHA1&digits=10&period=40";
    NSError *error = nil;
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url] error:&error];
    XCTAssertNil(credential, @"Credential with invalid digits secret is not nil.");
    XCTAssert(error.code == 6);
}

- (void)test_NoSecret_CredentialIsNil {
    NSError *error = nil;
    
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithType:YKFOATHCredentialTypeTOTP
                                                                                  algorithm:YKFOATHCredentialAlgorithmSHA1
                                                                                     secret:[NSData new]
                                                                                     issuer:nil
                                                                                accountName:@"Yubico"
                                                                                     digits:6
                                                                                     period:30
                                                                                    counter:0
                                                                                      error:&error];
    
    XCTAssertNil(credential);
    XCTAssertTrue(error.code == 6);
}

- (void)test_CorrectData_CredentialIsNotNil {
    NSError *error = nil;
    NSData *secret = [NSData ykf_dataWithBase32String:@"aaaaa"];

    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithType:YKFOATHCredentialTypeTOTP
                                                                                  algorithm:YKFOATHCredentialAlgorithmSHA1
                                                                                     secret:secret
                                                                                     issuer:nil
                                                                                accountName:@"Yubico"
                                                                                     digits:6
                                                                                     period:30
                                                                                    counter:0
                                                                                      error:&error];
    
    XCTAssertNotNil(credential);
    XCTAssertNil(error);
}

- (void)test_WhenCredentialIsCreatedWithHOTPURLWithoutSecret_CredentialIsNil {
    NSString *url = @"otpauth://hotp/ACME:john@example.com?issuer=ACME&algorithm=SHA1&digits=6&counter=1234";
    NSError *error = nil;
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url] error:&error];
    XCTAssertNil(credential, @"Credential without secret is not nil.");
    XCTAssert(error.code == 6);
}

- (void)test_WhenCredentialIsCreatedWithShortSecret_CredentialSecretIsPadded {
    NSString *url = @"otpauth://totp/Label?secret=HXDMVJEC&issuer=Issuer";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    XCTAssert(credential.secret.length == 14, @"Credential with short secret is not padded");
}

- (void)test_WhenCredentialIsCreatedWithLongSHA1Secret_CredentialSecretIsHashed {
    NSString *url = @"otpauth://totp/Label?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZHXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZHXDMVJECJJWSRB3HWIZR4IFUGFTMXHXDMVJECJJWS&issuer=Issuer";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    XCTAssert(credential.secret.length <= 64, @"Credential with long secret is not hashed.");
}

- (void)test_WhenCredentialIsCreatedWithLongSHA256Secret_CredentialSecretIsHashed {
    NSString *url = @"otpauth://totp/Label?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZHXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZHXDMVJECJJWSRB3HWIZR4IFUGFTMXHXDMVJECJJWS&issuer=Issuer&algorithm=SHA256";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    XCTAssert(credential.secret.length <= 64, @"Credential with long secret is not hashed.");
}

- (void)test_WhenCredentialIsCreatedWithLongSHA512Secret_CredentialSecretIsHashed {
    NSString *url = @"otpauth://totp/Label?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZHXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZHXDMVJECJJWSRB3HWIZR4IFUGFTMXHXDMVJECJJWSHXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZHXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZHXDMVJECJJWSRB3HWIZR4IFUGFTMXHXDMVJECJJWS&issuer=Issuer&algorithm=SHA512";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    XCTAssert(credential.secret.length <= 128, @"Credential with long secret is not hashed.");
}

- (void)test_WhenCredentialIsCreatedWithTOTPURLWithoutSecret_CredentialIsNil {
    NSString *url = @"otpauth://totp/ACME:john@example.com?issuer=ACME&algorithm=SHA1&digits=6&period=30";
    NSError *error = nil;
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url] error:&error];
    XCTAssertNil(credential, @"Credential without secret is not nil.");
    XCTAssert(error.code == 6);
}


- (void)test_WhenCredentialIsCreatedWithURLWithoutLabel_CredentialIsNil {
    NSString *url = @"otpauth://totp?secret=HXDMV&issuer=ACME&algorithm=SHA1&digits=6&period=30";
    NSError *error = nil;
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url] error:&error];
    XCTAssertNil(credential, @"Credential with missing label is not nil.");
    XCTAssert(error.code == 2);
}

- (void)test_WhenCredentialIsCreatedWithURLWithoutOTPType_CredentialIsNil {
    NSString *url = @"otpauth://ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6&period=30";
    NSError *error = nil;
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url] error:&error];
    XCTAssertNil(credential, @"Credential with missing label is not nil.");
    XCTAssert(error.code == 2);
}

- (void)test_WhenCredentialIsCreatedWithURLWithoutAlgorithm_CredentialAlgorithmIsSHA1 {
    NSString *url = @"otpauth://totp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&digits=6&period=30";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url]];
    XCTAssert(credential.algorithm == YKFOATHCredentialAlgorithmSHA1 , @"Credential does not default to SHA1.");
}

- (void)test_WhenValidatorReceivesValidTOTPCredential_NoErrorIsReturned {
    NSError *error = nil;
    NSString *url = @"otpauth://totp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6&period=30";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url] error:&error];
    XCTAssertNotNil(credential);
    XCTAssertNil(error);
}

- (void)test_DisableValidation_NoErrorIsReturned {
    NSError *error = nil;
    NSString *url = @"otpauth://totp/?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6&period=30";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url] skipValidation:YKFOATHCredentialTemplateValidationLabel error:&error];
    XCTAssertNotNil(credential);
    XCTAssertNil(error);
}

- (void)test_WhenValidatorReceivesValidHOTPCredential_NoErrorIsReturned {
    NSError *error = nil;
    NSString *url = @"otpauth://hotp/ACME:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6&counter=123";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url] error:&error];
    XCTAssertNotNil(credential);
    XCTAssertNil(error);
}

- (void)test_WhenValidatorIsRequestedToValidateWithoutSecret_SecretIsNotValidated {
    NSString *urlFormat = @"otpauth://hotp/ACME:john@example.com?secret=%@&issuer=ACME&algorithm=SHA256&digits=6&counter=123";
    NSString *url = [NSString stringWithFormat:urlFormat, YKFOATHCredentialValidatorTestsVeryLargeSecret];
    NSError *error = nil;
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url] error:&error];
    XCTAssertNotNil(credential);
    XCTAssertNil(error);
}

- (void)test_WhenNoPathIsSet_ErrorIsReturned {
    NSError *error = nil;
    NSString *url = @"otpauth://totp?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&algorithm=SHA1&digits=6&period=30";
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url] skipValidation:YKFOATHCredentialTemplateValidationLabel error:&error];
    XCTAssertNotNil(error);
    XCTAssertNil(credential);
}

#pragma mark - Large Key Tests

- (void)test_WhenValidatorReceivesInvalidCredentialKey_ErrorIsReturnedBack {
    NSString *urlFormat = @"otpauth://hotp/ACME:john_with_too_long_name_which_does_not_really_fit_in_the_key@example.com?secret=%@&issuer=ACME&algorithm=SHA1&digits=6&counter=123";
    NSString *url = [NSString stringWithFormat:urlFormat, YKFOATHCredentialValidatorTestsVeryLargeSecret];
    NSError *error = nil;
    YKFOATHCredentialTemplate *credential = [[YKFOATHCredentialTemplate alloc] initWithURL:[NSURL URLWithString:url] error:&error];
    XCTAssertNil(credential);
    XCTAssertTrue(error.code == 8);
}

@end
