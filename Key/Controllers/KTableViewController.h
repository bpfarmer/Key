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

@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray *sectionCriteria;
@property (nonatomic) NSArray *sectionData;
@property (nonatomic) NSString *sortedByProperty;
@property (nonatomic) BOOL sortDescending;

- (KDatabaseObject *)objectForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)cellIdentifier;
+ (dispatch_queue_t)sharedQueue;
- (NSArray *)modifySectionData:(NSArray *)sectionData;

@end
