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
    FreeKey *testFreeKey = [FreeKey sharedManager];
    NSArray *preKeys = [testFreeKey generatePreKeysForUser:user];
    XCTAssert([preKeys count] == 100);
}

- (void)testPreKeySending {
    KUser *user = [[KUser alloc] initWithUniqueId:@"12345"];
    FreeKey *testFreeKey = [FreeKey sharedManager];
    NSArray *preKeys = [testFreeKey generatePreKeysForUser:user];
    [testFreeKey sendPreKeysToServer:preKeys];
    // TODO: how do we test reception?
}

- (void)testRetrieveUser {
    
}

- (void)testSessionCreationAndEncryption {
    
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
    
    [alice save];
    [bob save];
    
    ECKeyPair *bobSignedPreKeyPair      = [Curve25519 generateKeyPair];
    NSData    *bobSignedPreKeySignature = [Ed25519 sign:bobSignedPreKeyPair.publicKey withKeyPair:bobIdentityKey.keyPair];
    
    NSDictionary *bobPreKeyDictionary = @{@"userId" : bobId,
                                          @"signedPreKeyId" : @"42",
                                          @"signedPreKeyPublic" : bobSignedPreKeyPair.publicKey,
                                          @"signedPreKeySignature" : bobSignedPreKeySignature,
                                          @"identityKey" : bobIdentityKey.publicKey};
    
    [[FreeKey sharedManager] createPreKeyFromRemoteDictionary:bobPreKeyDictionary];
    
    KMessage *message = [[KMessage alloc] initWithAuthorId:aliceId threadId:@"1" body:@"HERE"];
    
    [self measureBlock:^{
        [[FreeKey sharedManager] encryptObject:message localUser:alice recipientId:bobId];
    }];
    
    //XCTAssert(YES, @"Pass");
}



- (void)testPerformanceSetupPreKeys {
    KUser *user = [[KUser alloc] initWithUniqueId:@"1"];
    [self measureBlock:^{
        FreeKey *freeKey = [[FreeKey alloc] init];
        [freeKey generatePreKeysForUser:user];
    }];
}

@end
