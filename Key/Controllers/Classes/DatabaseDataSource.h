//
//  DatabaseDataSource.h
//  Key
//
//  Created by Brendan Farmer on 9/29/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class KDatabaseObject;

typedef UITableViewCell * (^ConfigureCellBlock)(UITableViewCell *cell, KDatabaseObject *object);
typedef BOOL (^SectionCriteriaBlock)(KDatabaseObject *object, NSUInteger sectionId);
typedef NSComparisonResult (^SortBlock)(KDatabaseObject *object1, KDatabaseObject *object2);

@interface DatabaseDataSource : NSObject <UITableViewDataSource>

- (instancetype)initWithSectionData:(NSArray *)sectionData
                     cellIdentifier:(NSString *)cellIdentifier
                          tableView:(UITableView *)tableView
                 configureCellBlock:(ConfigureCellBlock)configureCellBlock
               sectionCriteriaBlock:(SectionCriteriaBlock)sectionCriteriaBlock
                          sortBlock:(SortBlock)sortBlock;

- (void)registerForUpdatesFromClasses:(NSArray *)classNames;

@end
