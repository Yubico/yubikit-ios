//
//  TestListViewController.m
//  YubiKitFullStackTests
//
//  Created by Conrad Ciobanica on 2018-05-15.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <YubiKit/YubiKit.h>
#import "TestListViewController.h"
#import "ManualTests.h"

@interface TestListViewController()<UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *insertKeyView;
@property (nonatomic, assign) BOOL observeKeyConnected;

@end

@implementation TestListViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    self.observeKeyConnected = YES;
    [self updateKeyWarningViewVisibility];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.observeKeyConnected = NO;
}

- (void)dealloc {
    self.observeKeyConnected = NO;
}

#pragma mark - KVO

- (void)setObserveKeyConnected:(BOOL)observeKeyConnected {
    if (_observeKeyConnected == observeKeyConnected) {
        return;
    }
    _observeKeyConnected = observeKeyConnected;
    
    void *context = (__bridge void * _Nullable)(self.class);
    YKFAccessorySession *accessorySession = YubiKitManager.shared.accessorySession;
    
    if (_observeKeyConnected) {
        [accessorySession addObserver:self forKeyPath:YKFAccessorySessionStatePropertyKey options:0 context:context];
    } else {
        [accessorySession removeObserver:self forKeyPath:YKFAccessorySessionStatePropertyKey];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    void *currentContext = (__bridge void * _Nullable)(self.class);
    if (context != currentContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if ([keyPath isEqualToString:YKFAccessorySessionStatePropertyKey]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf updateKeyWarningViewVisibility];
        });
    }
}

- (void)updateKeyWarningViewVisibility {
    YKFAccessorySession *accessorySession = YubiKitManager.shared.accessorySession;
    self.insertKeyView.hidden = (accessorySession.sessionState == YKFAccessorySessionStateOpen);
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self performSegueWithIdentifier:@"ManualTestLogsPresentation" sender:self];
    [self.tableDataSource executeTestEntryAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 60;
}

@end
