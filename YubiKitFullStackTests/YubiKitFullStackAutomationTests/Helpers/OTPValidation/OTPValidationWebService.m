//
//  OTPValidationWebService.m
//  YubiKitFullStackAutomationTests
//
//  Created by Conrad Ciobanica on 2018-08-09.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OTPValidationWebService.h"
#import "OTPValidationWebServiceResponse.h"

/*
 Yubicloud API key
 
 Client ID:    39478
 Secret key:   riXK2pDucDX3lLvxQO3b/hLSgBY=
 */

@interface OTPValidationWebService()

@property (nonatomic) NSURLSession *urlSession;

@end

static NSString *verificationWSEndpoint = @"http://api.yubico.com/wsapi/2.0/verify";
static NSString *verificationWSEndpointClientID = @"39478";

@implementation OTPValidationWebService

static OTPValidationWebService *sharedInstance;

+ (OTPValidationWebService *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[OTPValidationWebService alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.urlSession = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration];
    }
    return self;
}

- (BOOL)validateOTP:(NSString *)otp {
    NSDictionary *requestResult = [self requestValidationForOTP:otp];
    if (!requestResult) {
        return NO;
    }    
    OTPValidationWebServiceResponse *response = [[OTPValidationWebServiceResponse alloc] initWithDictionary:requestResult];
    return response.isValid;
}

#pragma mark - Helpers

- (NSURLRequest *)verificationURLRequestForOTP:(NSString *)otp {
    NSURL *baseURL = [[NSURL alloc] initWithString:verificationWSEndpoint];
    NSURLComponents *requestURLComponents = [NSURLComponents componentsWithURL:baseURL resolvingAgainstBaseURL:NO];
    
    NSUUID *uuid = [NSUUID UUID];
    NSString *nonce = [uuid.UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    NSArray *queryItems = @[[NSURLQueryItem queryItemWithName:@"id" value:verificationWSEndpointClientID],
                            [NSURLQueryItem queryItemWithName:@"otp" value:otp],
                            [NSURLQueryItem queryItemWithName:@"nonce" value:nonce]];
    requestURLComponents.queryItems = queryItems;
 
    NSURL *requestURL = requestURLComponents.URL;
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];

    return request;
}

- (NSDictionary *)requestValidationForOTP:(NSString *)otp {
    if (!otp.length) {
        return nil;
    }
    
    NSURLRequest *request = [self verificationURLRequestForOTP: otp];
    
    __block NSMutableDictionary *responseDictionary = [[NSMutableDictionary alloc] init];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"OTP verification call success."];
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            [expectation fulfill];
            return;
        }

        /*
         The string returned from the service is not a JSON!!
         It's a list of key-value separated by newlines. Implemented a basic shaky parser.
         */
        NSString *stringResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSArray *parameters = [stringResponse componentsSeparatedByString:@"\r\n"];
        for (NSString *keyValuePair in parameters) {
            NSArray *pair = [keyValuePair componentsSeparatedByString:@"="];
            if (pair.count != 2) {
                continue;
            }
            responseDictionary[pair[0]] = pair[1];
        }
        
        [expectation fulfill];
    }];
    [task resume];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:30];
    if (result != XCTWaiterResultCompleted) {
        return nil;
    }
    
    return responseDictionary;
}

@end
