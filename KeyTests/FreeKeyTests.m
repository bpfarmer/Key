//
//  FreeKeyTests.m
//  FreeKeyTests
//
//  Created by Brendan Farmer on 3/2/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "FreeKey.h"
#import "KUser.h"
#import "KStorageManager.h"

@interface FreeKeyTests : XCTestCase

@end

@implementation FreeKeyTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPreKeyGeneration {
    KUser *user = [[KUser alloc] initWithUniqueId:@"12345"];
    FreeKey *testFreeKey = [[FreeKey alloc] init];
    NSArray *preKeys = [testFreeKey generatePreKeysForUser:user];
    XCTAssert([preKeys count] == 100);
}

- (void)testPreKeySending {
    KUser *user = [[KUser alloc] initWithUniqueId:@"12345"];
    FreeKey *testFreeKey = [[FreeKey alloc] init];
    NSArray *preKeys = [testFreeKey generatePreKeysForUser:user];
    [testFreeKey sendPreKeysToServer:preKeys];
    // TODO: how do we test reception?
}

- (void)testRetrieveUser {
    
}

- (void)testSessionCreation {
    FreeKey *freeKey = [[FreeKey alloc] init];
    
    XCTAssert(YES, @"Pass");
}



- (void)testPerformanceSetupPreKeys {
    KUser *user = [[KUser alloc] initWithUniqueId:@"1"];
    [self measureBlock:^{
        FreeKey *freeKey = [[FreeKey alloc] init];
        [freeKey generatePreKeysForUser:user];
    }];
}

@end
