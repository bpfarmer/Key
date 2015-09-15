//
//  KDatabaseObjectTests.m
//  Key
//
//  Created by Brendan Farmer on 7/7/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "KUser.h"
#import "KStorageManager.h"
#import "KAccountManager.h"
#import "CollapsingFutures.h"
#import "KPost.h"
#import "KTestHelper.h"

@interface KDatabaseObjectTests : XCTestCase

@end

@interface KDatabaseObject (Testing)

+ (NSString *)sqlStatementForDictionary:(NSDictionary *)dictionary;

@end

@implementation KDatabaseObjectTests

- (void)setUp {
    [super setUp];
    [KTestHelper setup];
}

- (void)tearDown {
    [super tearDown];
    [KTestHelper tearDown];
}

- (void)testDropTable {
    [KUser dropTable];
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

- (void)testSaveObject {
    KUser *user = [[KUser alloc] initWithUniqueId:@"12345" username:@"brendan" publicKey:nil];
    [user save];
    FMResultSet *resultSet = [[KStorageManager sharedManager].database executeQuery:[NSString stringWithFormat:@"select * from %@ where unique_id = ?", [KUser tableName]], @"12345"];
    while(resultSet.next) {
        XCTAssert([resultSet.resultDictionary[@"unique_id"] isEqualToString:@"12345"]);
    }
    [resultSet close];
}

- (void)testRetrieveObject {
    KUser *newUser = [[KUser alloc] initWithUniqueId:@"12345" username:@"brendan" publicKey:nil];
    [newUser save];
    KUser *user = [KUser findById:@"12345"];
    XCTAssert(user.uniqueId = @"12345");
    XCTAssert(user.username = @"brendan");
}

- (void)testRemoveObject {
    KUser *newUser = [[KUser alloc] initWithUniqueId:@"12345" username:@"brendan" publicKey:nil];
    [newUser save];
    [newUser remove];
    KUser *user = [KUser findById:@"12345"];
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

- (void)testAll {
    KUser *user1 = [[KUser alloc] initWithUniqueId:@"1" username:@"1" publicKey:nil];
    [user1 save];
    KUser *user2 = [[KUser alloc] initWithUniqueId:@"2" username:@"2" publicKey:nil];
    [user2 save];
    KUser *user3 = [[KUser alloc] initWithUniqueId:@"3" username:@"3" publicKey:nil];
    [user3 save];
    
    NSArray *users = [KUser all];
    NSMutableArray *userIds = [[NSMutableArray alloc] init];
    for(KUser *user in users) {
        [userIds addObject:user.uniqueId];
    }
    XCTAssert([userIds containsObject:@"1"]);
    XCTAssert([userIds containsObject:@"2"]);
    XCTAssert([userIds containsObject:@"3"]);
}

- (void)testSQLStatement {
    NSString *statement = [KPost sqlStatementForDictionary:@{@"uniqueId" : @"123"}];
    XCTAssert([statement isEqualToString:@"select * from k_post where (unique_id = :unique_id)"]);
    statement = [KPost sqlStatementForDictionary:@{@"uniqueId" : @[@">", @"123"]}];
    XCTAssert([statement isEqualToString:@"select * from k_post where (unique_id > :unique_id)"]);
    statement = [KPost sqlStatementForDictionary:@{@"uniqueId" : @[@"<", @"123"]}];
    XCTAssert([statement isEqualToString:@"select * from k_post where (unique_id < :unique_id)"]);
    statement = [KPost sqlStatementForDictionary:@{@"uniqueId" : @[@">=", @"123"]}];
    XCTAssert([statement isEqualToString:@"select * from k_post where (unique_id >= :unique_id)"]);
    statement = [KPost sqlStatementForDictionary:@{@"uniqueId" : @[@"<=", @"123"]}];
    XCTAssert([statement isEqualToString:@"select * from k_post where (unique_id <= :unique_id)"]);
    statement = [KPost sqlStatementForDictionary:@{@"uniqueId" : @[@"<>", @"123"]}];
    XCTAssert([statement isEqualToString:@"select * from k_post where (unique_id <> :unique_id)"]);
    statement = [KPost sqlStatementForDictionary:@{@"uniqueId" : @[@"=", @"123"]}];
    XCTAssert([statement isEqualToString:@"select * from k_post where (unique_id = :unique_id)"]);
    NSString *readAtCriterion = [NSString stringWithFormat:@"%f or read_at is null", [[NSDate dateWithTimeIntervalSinceNow:(-60*60*24)] timeIntervalSinceReferenceDate]];
    statement = [KPost sqlStatementForDictionary:@{@"ephemeral" : @NO, @"readAt" : @[@">", readAtCriterion]}];
    [KPost findByDictionary:@{@"ephemeral" : @NO, @"readAt" : @[@">", readAtCriterion]}];
    NSLog(@"READ AT CRITERION: %@", statement);
}

- (void)testFindAllWhere {
    KPost *post = [[KPost alloc] initWithAuthorId:@"1"];
    [post save];
    post = [[KPost alloc] initWithAuthorId:@"2"];
    [post save];
    post = [[KPost alloc] initWithAuthorId:@"3"];
    [post save];
    
    NSArray *posts = [KPost findAllWhere:@"author_id = :author1 or author_id = :author2 or author_id = :author3" parameters:@{@"author1" : @"1", @"author2" : @"2", @"author3" : @"3"}];
    XCTAssert(posts.count == 3);
}

@end