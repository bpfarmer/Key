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
#import "IdentityKey.h"
#import "Session.h"
#import <25519/Curve25519.h>
#import <25519/Ed25519.h>
#import "PreKey.h"
#import "KMessage.h"
#import "PreKeyExchange.h"
#import "EncryptedMessage.h"
#import "NSData+Base64.h"
#import "RootChain.h"
#import "ChainKey.h"
#import "MessageKey.h"
#import "FreeKeySessionManagerTests.m"

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
    FreeKey *testFreeKey = [FreeKeySessionManager sharedManager];
    NSArray *preKeys = [testFreeKey generatePreKeysForUser:user];
    XCTAssert([preKeys count] == 100);
}

- (void)testPreKeySending {
    KUser *user = [[KUser alloc] initWithUniqueId:@"12345"];
    FreeKey *testFreeKey = [FreeKeySessionManager sharedManager];
    NSArray *preKeys = [testFreeKey generatePreKeysForUser:user];
    [testFreeKey sendPreKeysToServer:preKeys];
}


@end
