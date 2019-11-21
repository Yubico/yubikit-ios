//
//  OTPUIResponder.m
//  YubiKitFullStackManualTests
//
//  Created by Conrad Ciobanica on 2018-08-09.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import "OTPUIResponder.h"

@interface OTPUIResponder()

@property (nonatomic) NSMutableArray* listOfkeyCommands;
@property (nonatomic) NSMutableString* otp;

@end

@implementation OTPUIResponder

static NSString* const acceptedCharacters = @"cbdefghijklnrtuv\r"; // modhex and return only
static NSString* const acceptedNumbers = @"0123456789";

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    NSString *commands = [acceptedNumbers stringByAppendingString:acceptedCharacters];
    self.listOfkeyCommands = [[NSMutableArray alloc] initWithCapacity:commands.length];
    
    for (int i = 0; i < commands.length; ++i) {
        unichar keyCommandChar = [commands characterAtIndex:i];
        NSString *keyCommandString = [NSString stringWithCharacters:&keyCommandChar length:1];
        
        UIKeyCommand *keyCommand = [UIKeyCommand keyCommandWithInput:keyCommandString modifierFlags:0 action:@selector(characterReceived:)];
        [self.listOfkeyCommands addObject:keyCommand];
    }
}

- (void)characterReceived:(UIKeyCommand *)sender {
    if (!self.otp.length) {
        [self.delegate otpUIResponderDidStartReadingOTP:self];
        self.otp = [[NSMutableString alloc] init];
        NSLog(@"OTP receiving started.");
    }
    
    if ([sender.input isEqualToString:@"\r"]) {
        [self.delegate otpUIResponder:self didReadOTP:self.otp];
        self.otp = nil;        
        NSLog(@"OTP receiving ended.");
        return;
    }
    
    [self.otp appendString:sender.input];
}

- (NSArray *)keyCommands {
    return self.listOfkeyCommands;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)setEnabled:(BOOL)enabled {
    if (_enabled == enabled) {
        return;
    }
    _enabled = enabled;
    
    if (_enabled) {
        [self becomeFirstResponder];
    } else {
        [self resignFirstResponder];
    }
}

@end
