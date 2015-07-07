//
//  KUserTests.m
//  Key
//
//  Created by Brendan Farmer on 3/13/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "KUser.h"
#import "KStorageManager.h"
#import "KAccountManager.h"
#import "CollapsingFutures.h"

@interface KUserTests : XCTestCase

@end

@implementation KUserTests

- (void)setUp {
    NSString *testDB = @"testDB";
    [super setUp];
    KStorageManager *manager = [KStorageManager sharedManager];
    [manager setDatabaseWithName:testDB];
    [KUser createTable];
}

- (void)tearDown {
    NSString *testDB = @"testDB";
    [super tearDown];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *databasePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@", [KStorageManager sharedManager].database.databasePath] error:nil];
}

- (void)testCreateTable {
    [KUser createTable];
}

- (void)testSaveUser {
    KUser *user = [[KUser alloc] initWithUniqueId:@"12345" username:@"brendan" publicKey:nil];
    [user save];
}

- (void)testFindAll {
    XCTestExpectation *queryExpectation = [self expectationWithDescription:@"retrieving users"];
    KUser *user = [[KUser alloc] initWithUniqueId:@"12345" username:@"brendan" publicKey:nil];
    [user save];
    NSLog(@"DB PATH: %@", [KStorageManager sharedManager].database.databasePath);
    TOCFuture *futureUsers = [KUser all];
    [futureUsers thenDo:^(NSArray *value) {
        NSLog(@"WHAT WE WORKIN WITH: %@", value);
        //XCTAssert(value.count == 1);
        [queryExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
        
    }];
}

- (void)testDropTable {
    [KUser dropTable];
}

@end

