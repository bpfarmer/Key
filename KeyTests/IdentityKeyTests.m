//
//  KeyTests.m
//  KeyTests
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "IdentityKey.h"
#import <25519/Curve25519.h>
#import <25519/Ed25519.h>

@interface IdentityKeyTests : XCTestCase

@end

@implementation IdentityKeyTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSerialization {
    NSString *uniqueId = @"12345";
    NSString *userId   = @"12345";
    ECKeyPair *keyPair = [Curve25519 generateKeyPair];
    
    /*
    IdentityKey *identityKey = [[IdentityKey alloc] initWithUniqueId:uniqueId userId:userId publicKey:keyPair.publicKey keyPair:keyPair];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:identityKey];
    IdentityKey *retrievedKey = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    // This is an example of a functional test case.
    XCTAssert([identityKey.uniqueId isEqual:retrievedKey.uniqueId]);
    */
}

@end
