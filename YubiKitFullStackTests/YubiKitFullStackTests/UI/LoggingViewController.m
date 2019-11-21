//
//  LoggingViewController.m
//  YubiKitFullStackTests
//
//  Created by Conrad Ciobanica on 2018-05-16.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <YubiKit/YubiKit.h>

#import "LoggingViewController.h"
#import "TestSharedLogger.h"
#import "Configuration.h"
#import "OTPUIResponder.h"

@interface LoggingViewController()<OTPUIResponderDelegate>

@property (strong, nonatomic) IBOutlet UITextView *logsTextView;

// Keep a reference to lower the memory footprint.
@property (nonatomic) NSMutableAttributedString *logString;

@property (nonatomic) OTPUIResponder *otpUIResponder;
@property (nonatomic, readwrite) NSString *otp;

@end

@implementation LoggingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.logString = [[NSMutableAttributedString alloc] init];
    
    self.otpUIResponder = [[OTPUIResponder alloc] init];
    self.otpUIResponder.delegate = self;
    [self.view addSubview:self.otpUIResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    TestSharedLogger.shared.loggingViewController = self;
    
    self.otpUIResponder.enabled = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    TestSharedLogger.shared.loggingViewController = nil;
    
    self.otpUIResponder.enabled = NO;
}

#pragma mark - Logging

- (NSAttributedString*) createAttributedStringFromMessage: (NSString*) message {
    return [self createAttributedStringFromResult: nil withResultColor: nil message: message];
}

- (NSAttributedString*) createAttributedStringFromResult: (NSString*) result withResultColor: (UIColor*) resultColor message: (NSString*) message {
    // Build the new line
    NSMutableString *mutableMessage = [message mutableCopy];
    [mutableMessage appendString: @"\n"];

    NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString: @""];
    if (result != nil && resultColor != nil) {
        [attributedString appendAttributedString: [[NSAttributedString alloc] initWithString: result attributes: @{ NSForegroundColorAttributeName: resultColor }]];
    }

    if (@available(iOS 13.0, *)) {
        [attributedString appendAttributedString: [[NSAttributedString alloc] initWithString: mutableMessage attributes: @{NSForegroundColorAttributeName: UIColor.labelColor}]];
    } else {
        [attributedString appendAttributedString: [[NSAttributedString alloc] initWithString: mutableMessage]];
    }
    return attributedString;
}

- (void) log: (NSString*) message {
    NSAttributedString* attributedString = [self createAttributedStringFromMessage: message];
    [self logAttributedString: attributedString];
}

- (void) logError: (NSString*) message {
    NSAttributedString* attributedString = [self createAttributedStringFromResult: @"Error: " withResultColor: UIColor.redColor message: message];
    [self logAttributedString: attributedString];
}

- (void) logSuccess: (NSString*) message {
    NSAttributedString* attributedString = [self createAttributedStringFromResult: @"Success: " withResultColor: UIColor.greenColor message: message];
    [self logAttributedString: attributedString];
}

#pragma mark - Log helpers

- (void)logAttributedString:(NSAttributedString *)attributedString {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(self) strongSelf = weakSelf;
        
        [strongSelf.logString appendAttributedString:attributedString];
        strongSelf.logsTextView.attributedText = strongSelf.logString;
        
        CGFloat bottom = strongSelf.logsTextView.contentSize.height - strongSelf.logsTextView.bounds.size.height;
        if (bottom > 0) {
            [strongSelf.logsTextView setContentOffset:CGPointMake(0, bottom) animated:YES];
        }
    });
}

#pragma mark - Actions

- (IBAction)dismissButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [YubiKitManager.shared.accessorySession cancelCommands];
}

#pragma mark - OTPUIResponderDelegate

- (void)otpUIResponder:(OTPUIResponder *)responder didReadOTP:(NSString *)otp {
    self.otp = otp;
}

- (void)otpUIResponderDidStartReadingOTP:(OTPUIResponder *)responder {
    // Do nothing
}

@end
