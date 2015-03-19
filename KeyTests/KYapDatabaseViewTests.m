//
//  KYapDatabaseViewTests.m
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
#import "KYapDatabaseView.h"

@interface KYapDatabaseViewTests : XCTestCase

@end

@implementation KYapDatabaseViewTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSavingThreads {
    /*
    KThread *thread = [[KThread alloc] initWithUsernames:@[@"1"]];
    [thread save];
    KMessage *testMessage = [[KMessage alloc] initWithAuthorId:@"1" threadId:thread.uniqueId body:@"TEST"];
    [testMessage save];
    YapDatabaseConnection *connection = [[KStorageManager sharedManager] dbConnection];
    
    __block NSInteger numOfKeys;
    [connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        numOfKeys = [transaction numberOfKeysInCollection:[KThread collection]];
    }];
    NSLog(@"NUM OF KEYS: %ld", (long)numOfKeys);
    */
}

@end