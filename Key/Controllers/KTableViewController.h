//
//  KTableViewController.h
//  Key
//
//  Created by Brendan Farmer on 8/24/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KDatabaseObject;

@interface KTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *sectionCriteria;
@property (nonatomic, strong) NSArray *sectionData;
@property (nonatomic) NSString *sortedByProperty;

- (KDatabaseObject *)objectForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)cellIdentifier;
+ (dispatch_queue_t)sharedQueue;

@end
