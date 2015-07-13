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
#import "FreeKeySessionManager.h"
#import "PreKey.h"
#import "PreKeyExchange.h"
#import "Session.h"
#import "RootChain.h"
#import "ChainKey.h"
#import "MessageKey.h"
#import "KStorageManager.h"
#import "FreeKeyTestExample.h"
#import "FreeKeyNetworkManager.h"
#import "KStorageSchema.h"

@interface FreeKeySessionManagerTests : XCTestCase

@property KUser *alice;
@property KUser *bob;
@property IdentityKey *aliceIdentityKey;
@property IdentityKey *bobIdentityKey;
@property ECKeyPair *aliceBaseKeyPair;
@property ECKeyPair *bobBaseKeyPair;
@property PreKey *bobPreKey;
@property PreKeyExchange *alicePreKeyExchange;

@end

@implementation FreeKeySessionManagerTests

- (void)setUp {
    [[KStorageManager sharedManager] setDatabaseWithName:@"testDB"];
    [KStorageSchema dropTables];
    [KStorageSchema createTables];
    FreeKeyTestExample *example = [[FreeKeyTestExample alloc] init];
    _alice            = example.alice;
    _bob              = example.bob;
    _aliceIdentityKey = example.aliceIdentityKey;
    _bobIdentityKey   = example.bobIdentityKey;
    _aliceBaseKeyPair = example.aliceBaseKeyPair;
    _bobBaseKeyPair   = example.bobBaseKeyPair;
    _bobPreKey        = example.bobPreKey;
    _alicePreKeyExchange = example.alicePreKeyExchange;
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/**
 *  Testing session initialization with a basic PrekeyWhisperMessage
 */

- (void)testSessionCreationWithPreKey {
    Session *session = [[FreeKeySessionManager sharedManager] createSessionWithLocalUser:_alice
                                                                              remoteUser:_bob
                                                                              ourBaseKey:_aliceBaseKeyPair theirPreKey:_bobPreKey];
    NSLog(@"SENDER CHAIN ID: %@", session.senderChainId);
    XCTAssert(session.senderChainId);
}

- (void)testSessionCreationWithPreKeyExchange {
    Session *session = [[FreeKeySessionManager sharedManager] createSessionWithLocalUser:_bob remoteUser:_alice ourPreKey:_bobPreKey theirPreKeyExchange:_alicePreKeyExchange];
    
    XCTAssert(session.senderChainId);
}

- (void)testSessionAgreement {
    Session *aliceSession = [[FreeKeySessionManager sharedManager] createSessionWithLocalUser:_alice
                                                                                   remoteUser:_bob
                                                                                   ourBaseKey:_aliceBaseKeyPair
                                                                                  theirPreKey:_bobPreKey];
    
    Session *bobSession = [[FreeKeySessionManager sharedManager] createSessionWithLocalUser:_bob
                                                                                 remoteUser:_alice
                                                                                  ourPreKey:_bobPreKey
                                                                        theirPreKeyExchange:_alicePreKeyExchange];
    
    //XCTAssert([aliceSession.senderRootChain.chainKey.messageKey.cipherKey isEqual:bobSession.receiverRootChain.chainKey.messageKey.cipherKey]);
    
}

- (void)testPreKeyGeneration {
    KUser *user = [[KUser alloc] initWithUniqueId:@"12345"];
    NSArray *preKeys = [[FreeKeyNetworkManager sharedManager] generatePreKeysForLocalUser:user];
    XCTAssert([preKeys count] == 100);
}

- (void)testPreKeySending {
    KUser *user = [[KUser alloc] initWithUniqueId:@"12345"];
    NSArray *preKeys = [[FreeKeyNetworkManager sharedManager] generatePreKeysForLocalUser:user];
    //[[FreeKeyNetworkManager sharedManager] sendPreKeysToServer:preKeys];
}

- (void)testPreKeyRetrieval {
    
}

@end