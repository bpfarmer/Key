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
    [super tearDown];
}

- (void)testPropertyNames {
    NSLog(@"PROPERTIES: %@", [KUser storedPropertyList]);
    NSLog(@"PROPERTY MAPPING: %@", [KUser propertyMapping]);
    KUser *user = [[KUser alloc] initWithUniqueId:@"12345" username:@"brendan" publicKey:nil];
    NSLog(@"INSTANCE MAPPING: %@", [user instanceMapping]);
}

- (void)testCreateTable {
    [KUser createTable];
}

- (void)testSaveUser {
    KUser *user = [[KUser alloc] initWithUniqueId:@"12345" username:@"brendan" publicKey:nil];
    [user save];
    FMResultSet *resultSet = [[KStorageManager sharedManager].database executeQuery:[NSString stringWithFormat:@"select * from %@ where unique_id = ?", [KUser tableName]], @"12345"];
    while(resultSet.next) {
        XCTAssert([resultSet.resultDictionary[@"unique_id"] isEqualToString:@"12345"]);
    }
    [resultSet close];
}

- (void)testRetrieveUser {
    KUser *newUser = [[KUser alloc] initWithUniqueId:@"12345" username:@"brendan" publicKey:nil];
    [newUser save];
    KUser *user = [KUser findByUniqueId:@"12345"];
    XCTAssert(user.uniqueId = @"12345");
    XCTAssert(user.username = @"brendan");
}

- (void)testRemoveUser {
    KUser *newUser = [[KUser alloc] initWithUniqueId:@"12345" username:@"brendan" publicKey:nil];
    [newUser save];
    [newUser remove];
    KUser *user = [KUser findByUniqueId:@"12345"];
    XCTAssert(!user);
}

- (void)testFindAll {
    [KUser createTable];
    KUser *user = [[KUser alloc] initWithUniqueId:@"12345" username:@"brendan" publicKey:nil];
    [user save];
    FMResultSet *allUsers = [KUser all];
    while(allUsers.next) {
        XCTAssert([allUsers.resultDictionary[@"unique_id"] isEqualToString:@"12345"]);
    }
    [allUsers close];
}

- (void)testDropTable {
    [KUser dropTable];
}

@end

