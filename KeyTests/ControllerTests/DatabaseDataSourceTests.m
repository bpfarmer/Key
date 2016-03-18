//
//  DatabaseDataSourceTests.m
//  Key
//
//  Created by Brendan Farmer on 9/29/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "KUser.h"
#import "KDevice.h"
#import "KStorageManager.h"
#import "KAccountManager.h"
#import "KStorageSchema.h"
#import "CollapsingFutures.h"
#import "KTestHelper.h"
#import "DatabaseDataSource.h"

@interface DatabaseDataSourceTests : XCTestCase

@end

@interface DatabaseDataSource ()
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray *sectionCriteria;
@property (nonatomic) NSArray *sectionData;

@property (nonatomic, copy) NSString *cellIdentifier;
@property (nonatomic, copy) ConfigureCellBlock configureCellBlock;
@property (nonatomic, copy) SectionCriteriaBlock sectionCriteriaBlock;
@property (nonatomic, copy) SortBlock sortBlock;

- (void)objectUpdated:(KDatabaseObject *)object;
- (void)updateSectionId:(NSUInteger)sectionId oldCellId:(NSInteger)oldCellId newCellId:(NSInteger)newCellId;
- (NSArray *)newDataForSectionId:(NSUInteger)sectionId oldCellId:(NSInteger)oldCellId newCellId:(NSInteger)newCellId object:(KDatabaseObject *)object;
- (NSInteger)destinationCellIdInSectionId:(NSUInteger)sectionId object:(KDatabaseObject *)object;
- (NSInteger)currentCellIdInSectionId:(NSUInteger)sectionId object:(KDatabaseObject *)object;
- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender;
- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section;
- (KDatabaseObject *)objectAtIndexPath:(NSIndexPath *)indexPath;

@end


@implementation DatabaseDataSourceTests

- (void)setUp {
    [super setUp];
    [KTestHelper setup];
}

- (void)tearDown {
    [super tearDown];
    [KTestHelper tearDown];
}

- (void)testInit {
    NSArray *sectionData = @[@[]];
    UITableView *tableView = [[UITableView alloc] init];
    UITableViewCell*(^configureCellBlock)(UITableViewCell*, KDatabaseObject*) = ^(UITableViewCell *cell, KDatabaseObject *object) {
        return cell;
    };
    BOOL(^sectionCriteriaBlock)(KDatabaseObject*, NSUInteger) = ^(KDatabaseObject *object, NSUInteger sectionId) {
        return YES;
    };
    NSComparisonResult (^sortBlock)(KDatabaseObject*, KDatabaseObject*) = ^(KDatabaseObject *object1, KDatabaseObject *object2) {
        return [object1.uniqueId compare:object2.uniqueId];
    };
    DatabaseDataSource *dataSource = [[DatabaseDataSource alloc] initWithSectionData:sectionData cellIdentifier:@"Cells" tableView:tableView configureCellBlock:configureCellBlock sectionCriteriaBlock:sectionCriteriaBlock sortBlock:sortBlock];
    XCTAssert(dataSource.sectionCriteriaBlock);
    XCTAssert(dataSource.configureCellBlock);
    XCTAssert(dataSource.tableView);
    XCTAssert(dataSource.sectionData);
    XCTAssert(dataSource.cellIdentifier);
    XCTAssert(dataSource.sortBlock);
}

- (void)testObjectAtIndexPath {
    NSArray *sectionData = @[@[[KUser findById:@"1"], [KUser findById:@"2"]], @[[KUser findById:@"3"], [KUser findById:@"4"]]];
    DatabaseDataSource *dataSource = [[DatabaseDataSource alloc] initWithSectionData:sectionData cellIdentifier:@"Cells" tableView:nil configureCellBlock:nil sectionCriteriaBlock:nil sortBlock:nil];
    XCTAssert(dataSource);
    XCTAssert([[dataSource objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] isEqual:[KUser findById:@"1"]]);
    XCTAssert([[dataSource objectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] isEqual:[KUser findById:@"2"]]);
    XCTAssert([[dataSource objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]] isEqual:[KUser findById:@"3"]]);
    XCTAssert([[dataSource objectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]] isEqual:[KUser findById:@"4"]]);
}

- (void)testNumberOfSectionsInTableView {
    NSArray *sectionData = @[@[[KUser findById:@"1"], [KUser findById:@"2"]], @[[KUser findById:@"3"], [KUser findById:@"4"]]];
    DatabaseDataSource *dataSource = [[DatabaseDataSource alloc] initWithSectionData:sectionData cellIdentifier:@"Cells" tableView:nil configureCellBlock:nil sectionCriteriaBlock:nil sortBlock:nil];
    XCTAssert([dataSource numberOfSectionsInTableView:nil] == 2);
}

- (void)testNumberOfRowsInSection {
    NSArray *sectionData = @[@[[KUser findById:@"1"], [KUser findById:@"2"]], @[[KUser findById:@"3"], [KUser findById:@"4"]]];
    DatabaseDataSource *dataSource = [[DatabaseDataSource alloc] initWithSectionData:sectionData cellIdentifier:@"Cells" tableView:nil configureCellBlock:nil sectionCriteriaBlock:nil sortBlock:nil];
    XCTAssert([dataSource tableView:nil numberOfRowsInSection:0] == 2);
    XCTAssert([dataSource tableView:nil numberOfRowsInSection:1] == 2);
}

- (void)testNewObject {
    NSArray *sectionData = @[@[[KUser findById:@"1"]], @[[KUser findById:@"3"]]];
    BOOL(^sectionCriteriaBlock)(KDatabaseObject*, NSUInteger) = ^(KDatabaseObject *object, NSUInteger sectionId) {
        if(sectionId == 0 && ([object.uniqueId isEqualToString:@"2"] || [object.uniqueId isEqualToString:@"1"])) return YES;
        if(sectionId == 1 && ([object.uniqueId isEqualToString:@"3"] || [object.uniqueId isEqualToString:@"4"])) return YES;
        return NO;
    };
    NSComparisonResult (^sortBlock)(KDatabaseObject*, KDatabaseObject*) = ^(KDatabaseObject *object1, KDatabaseObject *object2) {
        KUser *user1 = (KUser *)object1;
        KUser *user2 = (KUser *)object2;
        return [user1.username compare:user2.username];
    };
    
    KUser *newUser1 = [KUser findById:@"2"];
    KUser *newUser2 = [KUser findById:@"4"];
    DatabaseDataSource *dataSource = [[DatabaseDataSource alloc] initWithSectionData:sectionData cellIdentifier:@"Cells" tableView:nil configureCellBlock:nil sectionCriteriaBlock:sectionCriteriaBlock sortBlock:sortBlock];
    XCTAssert([dataSource tableView:nil numberOfRowsInSection:0] == 1);
    XCTAssert([dataSource tableView:nil numberOfRowsInSection:1] == 1);
    [dataSource objectUpdated:newUser1];
    [dataSource objectUpdated:newUser2];
    XCTAssert([dataSource tableView:nil numberOfRowsInSection:0] == 2);
    XCTAssert([dataSource tableView:nil numberOfRowsInSection:1] == 2);
    XCTAssert([((KUser *)[dataSource objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).username isEqualToString:@"2"]);
    newUser1.username = @"5";
    [dataSource objectUpdated:newUser1];
    XCTAssert([((KUser *)[dataSource objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).username isEqualToString:@"5"]);
    KUser *user1 = [KUser findById:@"1"];
    user1.username = @"4";
    [dataSource objectUpdated:user1];
    XCTAssert([((KUser *)[dataSource objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).username isEqualToString:@"4"]);
}


@end