//
//  ManualTestsViewController.m
//  YubiKitFullStackTests
//
//  Created by Conrad Ciobanica on 2018-05-24.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import "ManualTestsViewController.h"
#import "ManualTests.h"

@interface ManualTestsViewController() <UITableViewDelegate>
@end

@implementation ManualTestsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableDataSource = [[ManualTests alloc] initWithTableView:self.tableView];
}

@end
