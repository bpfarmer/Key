//
//  FreeKeySessionManagerTests.m
//  Key
//
//  Created by Brendan Farmer on 3/20/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "KUser.h"
#import <25519/Curve25519.h>
#import <25519/Ed25519.h>
#import "IdentityKey.h"
#import "NSData+Base64.h"

@interface FreeKeySessionManagerTests : XCTestCase

@end

@implementation FreeKeySessionManagerTests

- (void)setUp {
    NSString *bobId = @"bobUniqueId";
    NSString *aliceId = @"aliceUniqueId";
    
    KUser *alice = [[KUser alloc] initWithUniqueId:bobId];
    [alice setUsername:@"alice"];
    
    KUser *bob   = [[KUser alloc] initWithUniqueId:bobId];
    [bob setUsername:@"bob"];
    
    IdentityKey *aliceIdentityKey = [[IdentityKey alloc] initWithKeyPair:[Curve25519 generateKeyPair] userId:aliceId];
    [alice setIdentityKey:aliceIdentityKey];
    
    IdentityKey *bobIdentityKey = [[IdentityKey alloc] initWithKeyPair:[Curve25519 generateKeyPair] userId:bobId];
    [bob setPublicKey:bobIdentityKey.keyPair.publicKey];
    
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/**
 *  Testing session initialization with a basic PrekeyWhisperMessage
 */

- (void)test {
}

@end