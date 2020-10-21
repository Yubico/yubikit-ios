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

@interface TestListViewController()<UITableViewDelegate, YKFManagerDelegate>

@property (strong, nonatomic) IBOutlet UIView *insertKeyView;
@property (nonatomic, assign) BOOL observeKeyConnected;
@property (strong, nonatomic) YKFAccessoryConnection *connection;

@end

@implementation TestListViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    YubiKitManager.shared.delegate = self;
    self.insertKeyView.hidden = FALSE;
    [YubiKitManager.shared startAccessoryConnection];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"🦠 viewWillDisappear: %@", self);
    [YubiKitManager.shared stopAccessoryConnection];
}

- (void)dealloc {
    [YubiKitManager.shared stopAccessoryConnection];
    YubiKitManager.shared.delegate = nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self performSegueWithIdentifier:@"ManualTestLogsPresentation" sender:self];
    self.tableDataSource.connection = self.connection;
    [self.tableDataSource executeTestEntryAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 60;
}

#pragma mark - YubiKitManagerDelegate

- (void)didConnectAccessory:(YKFAccessoryConnection *_Nonnull)connection {
    self.connection = connection;
    self.insertKeyView.hidden = TRUE;
    NSLog(@"didConnectAccessory: %@", connection);
}

- (void)didConnectNFC:(YKFNFCConnection *_Nonnull)connection {
    NSLog(@"didConnectNFC: %@", connection);
}

- (void)didDisconnectAccessory:(YKFAccessoryConnection *_Nonnull)connection error:(NSError * _Nullable)error {
    self.connection = nil;
    self.insertKeyView.hidden = FALSE;
    NSLog(@"didDisconnectAccessory");
}

- (void)didDisconnectNFC:(YKFNFCConnection *_Nonnull)connection error:(NSError * _Nullable)error {
    NSLog(@"didDisconnectNFC");
}

@end
