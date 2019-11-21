//
//  GnubbyManualTestsViewController.m
//  YubiKitFullStackTests
//
//  Created by Conrad Ciobanica on 2018-05-24.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import "GnubbyManualTestsViewController.h"
#import "GnubbyManualTests.h"

@interface GnubbyManualTestsViewController() <UITableViewDelegate>
@end

@implementation GnubbyManualTestsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableDataSource = [[GnubbyManualTests alloc] initWithTableView:self.tableView];
}

@end
