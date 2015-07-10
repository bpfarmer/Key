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
#import "IdentityKey.h"
#import "KStorageSchema.h"
#import "Curve25519.h"
#import "PreKey.h"

@interface KUserTests : XCTestCase

@end

@implementation KUserTests

- (void)setUp {
    NSString *testDB = @"testDB";
    [super setUp];
    KStorageManager *manager = [KStorageManager sharedManager];
    [manager setDatabaseWithName:testDB];
    [KStorageSchema dropTables];
    [KStorageSchema createTables];
    KUser *user = [[KUser alloc] initWithUniqueId:@"12345" username:@"brendan" publicKey:nil];
    [user save];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testIdentityKeys {
    KUser *user = [KUser findById:@"12345"];
    [user setupIdentityKey];
    IdentityKey *idKey = [IdentityKey findByDictionary:@{@"userId" : user.uniqueId}];
    XCTAssert([idKey.userId isEqualToString:user.uniqueId]);
    IdentityKey *identityKey = [[IdentityKey alloc] initWithKeyPair:[Curve25519 generateKeyPair] userId:@"1"];
    [identityKey save];
    IdentityKey *key = [IdentityKey findByDictionary:@{@"userId" : @"1"}];
    NSLog(@"KEYPAIR: %@", [user identityKey].keyPair);
}

- (void)testPreKeys {
    KUser *user = [KUser findById:@"12345"];
    [user asyncSetupPreKeys];
    PreKey *preKey = [PreKey findByDictionary:@{@"userId" : @"12345"}];
    XCTAssert([preKey.userId isEqualToString:@"12345"]);
}

@end

