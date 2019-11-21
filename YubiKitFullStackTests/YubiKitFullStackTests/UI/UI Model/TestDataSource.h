//
//  TestDataSource.h
//  YubiKitFullStackTests
//
//  Created by Conrad Ciobanica on 2018-05-16.
//  Copyright © 2018 Yubico. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <YubiKit/YubiKit.h>

#import "TestDataGenerator.h"

NS_ASSUME_NONNULL_BEGIN

@interface TestDataSource: NSObject

@property (nonatomic) TestDataGenerator *testDataGenerator;
@property (nonatomic) NSArray *testList;

- (instancetype)initWithTableView:(UITableView *)tableView;

- (void)executeTestEntryAtIndexPath:(NSIndexPath*)indexPath;

#pragma mark - Command execution

- (void)executeU2FApplicationSelection;
- (void)executeGnubbyU2FApplicationSelection;
- (void)executeYubiKeyApplicationSelection;
- (void)executePivApplicationSelection;


- (void)executeCommandWithAPDU:(YKFAPDU *)apdu completion:(YKFKeyRawCommandServiceResponseBlock)completion;
- (void)executeCommandWithData:(NSData *)data completion:(YKFKeyRawCommandServiceResponseBlock)completion;

@end

NS_ASSUME_NONNULL_END
