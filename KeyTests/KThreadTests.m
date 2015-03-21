//
//  KThreadTests.m
//  Key
//
//  Created by Brendan Farmer on 3/18/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "KThread.h"
#import "KMessage.h"
#import "KStorageManager.h"
#import "KUser.h"

@interface KThreadTests : XCTestCase

@end

@implementation KThreadTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSavingThreads {
    KThread *thread = [[KThread alloc] initWithUniqueId:@"1"];
    [thread save];
    KMessage *testMessage = [[KMessage alloc] initWithAuthorId:@"1" threadId:thread.uniqueId body:@"TEST"];
    [testMessage save];
    YapDatabaseConnection *connection = [[KStorageManager sharedManager] dbConnection];
    
    __block NSInteger numOfKeys;
    [connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        numOfKeys = [transaction numberOfKeysInCollection:[KThread collection]];
    }];
    
    XCTAssert(numOfKeys > 0);
}

- (void)testSettingName {
    KUser *user1 = [[KUser alloc] initWithUniqueId:@"1"];
    [user1 setUsername:@"user1"];
    KUser *user2 = [[KUser alloc] initWithUniqueId:@"2"];
    [user2 setUsername:@"user2"];
    KUser *user3 = [[KUser alloc] initWithUniqueId:@"3"];
    [user3 setUsername:@"user3"];
    NSArray *users = @[user1, user2, user3];
    KThread *thread = [[KThread alloc] initWithUsers:users];
    XCTAssert([thread.name isEqualToString:@"user1, user2, user3"]);
    XCTAssert([thread.uniqueId isEqualToString:@"1_2_3"]);
}

@end