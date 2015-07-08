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
    NSLog(@"NEW PROPERTY NAME LIST: %@", [KUser propertyNames]);
    NSLog(@"PROPERTIES: %@", [KUser storedPropertyList]);
    NSLog(@"PROPERTY MAPPING: %@", [KUser columnToPropertyMapping]);
    NSLog(@"PROPERTY MAPPING: %@", [KUser propertyToColumnMapping]);
    KUser *user = [[KUser alloc] initWithUniqueId:@"12345" username:@"brendan" publicKey:nil];
    NSLog(@"INSTANCE MAPPING: %@", [user instanceMapping]);
    NSLog(@"UNIQUE ID TYPE: %@", [KUser typeOfPropertyNamed:@"uniqueId"]);
    NSLog(@"HAS_KEY TYPE: %@", [KUser typeOfPropertyNamed:@"hasLocalPreKey"]);
    [KUser createTable];
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

- (void)testFindByDictionary {
    [KUser createTable];
    KUser *user = [[KUser alloc] initWithUniqueId:@"12345" username:@"brendan" publicKey:nil];
    [user save];
    XCTAssert([((KUser *)[KUser findByDictionary:@{@"uniqueId" : @"12345", @"username" : @"brendan"}]).uniqueId isEqualToString:@"12345"]);
    XCTAssert([((KUser *)[KUser findByDictionary:@{@"uniqueId" : @"12345"}]).uniqueId isEqualToString:@"12345"]);
    XCTAssert([((KUser *)[KUser findByDictionary:@{@"username" : @"brendan"}]).username isEqualToString:@"brendan"]);
}

- (void)testDropTable {
    [KUser dropTable];
}

@end

