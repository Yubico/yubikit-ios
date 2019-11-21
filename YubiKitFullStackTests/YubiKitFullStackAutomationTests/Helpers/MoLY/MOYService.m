//
//  MoLYService.m
//  YubiKitFullStackManualTests
//
//  Created by Conrad Ciobanica on 2018-06-19.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MoLYService.h"
#import "TestSharedLogger.h"

static NSString* const MOYServiceEndpoint = @"http://192.168.2.2:8080/moly";

@interface MoLYService ()

@property (nonatomic) NSURLSession *urlSession;

@end

@implementation MoLYService

static MoLYService *sharedInstance;

+ (MoLYService *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MoLYService alloc] init];
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

#pragma mark - MOY Actions

- (BOOL)plugin {
    [TestSharedLogger.shared logMessage:@"MoLY: Plugin key."];
    return [self executeAction:@"plugin"];
}

- (BOOL)plugout {
    [TestSharedLogger.shared logMessage:@"MoLY: Plugout key."];
    return [self executeAction:@"plugout"];
}

- (BOOL)touch {
    [TestSharedLogger.shared logMessage:@"MoLY: Touch key."];
    return [self executeAction:@"touch"];
}

#pragma mark - Helpers

- (BOOL)executeAction:(NSString *)action {
    if (self.disabled) {
        return YES;
    }
    
    NSURLRequest *request = [self requestWithAction:action];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"MoLY call success."];
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [expectation fulfill];
    }];
    [task resume];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:5];
    
    return result == XCTWaiterResultCompleted;
}

- (NSURLRequest *)requestWithAction:(NSString *)action {
    NSURL *url = [NSURL URLWithString: MOYServiceEndpoint];
    NSString *requestBody = [NSString stringWithFormat:@"action=%@", action];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [requestBody dataUsingEncoding:NSUTF8StringEncoding];
    
    return request;
}

@end
