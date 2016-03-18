//
//  KStorageManagerTests.m
//  Key
//
//  Created by Brendan Farmer on 7/6/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "KStorageManager.h"

@interface KStorageManagerTests : XCTestCase

@end

@implementation KStorageManagerTests

- (void)setUp {
    NSString *testDB = @"testDB";
    [super setUp];
    KStorageManager *manager = [KStorageManager sharedManager];
    [manager setDatabaseWithName:testDB];
}

- (void)tearDown {
    [super tearDown];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@", [KStorageManager sharedManager].database.databasePath] error:nil];
}

- (void)testDatabaseCreation {
    KStorageManager *manager = [KStorageManager sharedManager];
    XCTAssert(manager.database.open);
    XCTAssert(manager.database.close);
}

@end
