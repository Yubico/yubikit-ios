//
//  TestListViewController.h
//  YubiKitFullStackTests
//
//  Created by Conrad Ciobanica on 2018-05-15.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TestDataSource.h"

@interface TestListViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) TestDataSource *tableDataSource;

@end

