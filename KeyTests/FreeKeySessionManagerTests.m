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
    NSString *bobId = @"bobUniqueId";
    NSString *aliceId = @"aliceUniqueId";
    
    _alice = [[KUser alloc] initWithUniqueId:bobId];
    [_alice setUsername:@"alice"];
    
    _bob   = [[KUser alloc] initWithUniqueId:bobId];
    [_bob setUsername:@"bob"];
    
    _aliceIdentityKey = [[IdentityKey alloc] initWithKeyPair:[Curve25519 generateKeyPair] userId:aliceId];
    [_alice setIdentityKey:_aliceIdentityKey];
    [_alice setPublicKey:_aliceIdentityKey.publicKey];
    
    _bobIdentityKey = [[IdentityKey alloc] initWithKeyPair:[Curve25519 generateKeyPair] userId:bobId];
    [_bob setPublicKey:_bobIdentityKey.keyPair.publicKey];
    [_bob setIdentityKey:_bobIdentityKey];
    
    _aliceBaseKeyPair = [Curve25519 generateKeyPair];
    _bobBaseKeyPair = [Curve25519 generateKeyPair];
    
    NSData *preKeySignature = [Ed25519 sign:_bobBaseKeyPair.publicKey withKeyPair:_bobIdentityKey.keyPair];
    _bobPreKey = [[PreKey alloc] initWithUserId:_bob.uniqueId
                                       deviceId:@"1"
                                 signedPreKeyId:@"1"
                             signedPreKeyPublic:_bobBaseKeyPair.publicKey
                          signedPreKeySignature:preKeySignature
                                    identityKey:_bobIdentityKey.publicKey
                                    baseKeyPair:_bobBaseKeyPair];
    
    NSData *preKeyExchangeSignature = [Ed25519 sign:_aliceBaseKeyPair.publicKey withKeyPair:_aliceIdentityKey.keyPair];
    _alicePreKeyExchange = [[PreKeyExchange alloc] initWithSenderId:_alice.uniqueId
                                                         receiverId:_bob.uniqueId
                                               signedTargetPreKeyId:@"1"
                                                  sentSignedBaseKey:_aliceBaseKeyPair.publicKey
                                            senderIdentityPublicKey:_aliceIdentityKey.publicKey
                                          receiverIdentityPublicKey:_bobIdentityKey.publicKey
                                                   baseKeySignature:preKeyExchangeSignature];
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
    XCTAssert(session.senderRootChain.chainKey);
}

- (void)testSessionCreationWithPreKeyExchange {
    Session *session = [[FreeKeySessionManager sharedManager] createSessionWithLocalUser:_bob remoteUser:_alice ourPreKey:_bobPreKey theirPreKeyExchange:_alicePreKeyExchange];
    
    XCTAssert(session.senderRootChain.chainKey);
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
    
    XCTAssert([bobSession.senderRootChain.chainKey.messageKey.cipherKey
               isEqual:aliceSession.receiverRootChain.chainKey.messageKey.cipherKey]);
    
}

@end