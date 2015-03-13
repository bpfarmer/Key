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

@interface KUserTests : XCTestCase

@end

@implementation KUserTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFetchingObjects {
    NSString *username = @"TESTER";
    KUser *savingUser = [[KUser alloc] initWithUsername:username];
    [savingUser setUniqueId:@"12345"];
    [[KAccountManager sharedManager] setUser:savingUser];
    [savingUser save];
    [[KStorageManager sharedManager] setupDatabase];
    KUser *retrievingUser = [KUser fetchObjectWithUsername:username];
    XCTAssert([retrievingUser.username isEqual:savingUser.username]);
}

- (void)testPasswordEncryptionAndLogin {
    NSString *username = @"TESTER";
    KUser *user = [[KUser alloc] initWithUsername:username];
    [user setUniqueId:@"12345"];
    [user setPasswordCryptInKeychain:@"12345"];
    [[KAccountManager sharedManager] setUser:user];
    [[KStorageManager sharedManager] setupDatabase];
    [user save];
    KUser *authenticatingUser = [[KUser alloc] initWithUsername:username];
    XCTAssert(![authenticatingUser authenticatePassword:@"123456"]);
    XCTAssert([authenticatingUser authenticatePassword:@"12345"]);
}

@end

