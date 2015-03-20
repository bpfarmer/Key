//
//  SessionBuilderTests.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/3/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Session.h"
#import "PreKey.h"
#import <25519/Ed25519.h>
#import <25519/Curve25519.h>
#import "EncryptedMessage.h"
#import "RootChain.h"
#import "ChainKey.h"
#import "RootKey.h"
#import "IdentityKey.h"
#import "MessageKey.h"
#import "AES_CBC.h"
#import "PreKeyExchange.h"
#import "KUser.h"

@interface SessionTests : XCTestCase

@property KUser *alice;
@property KUser *bob;
@property IdentityKey *aliceIdentityKey;
@property IdentityKey *bobIdentityKey;
@property ECKeyPair *aliceBaseKeyPair;
@property ECKeyPair *bobBaseKeyPair;
@property PreKey *bobPreKey;
@property PreKeyExchange *alicePreKeyExchange;

@end

@implementation SessionTests

- (void)setUp {
    [super setUp];
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

- (void)testSimpleExchange {
    Session *aliceSession = [[Session alloc] initWithReceiverId:_bob.uniqueId identityKey:_aliceIdentityKey];
    Session *bobSession   = [[Session alloc] initWithReceiverId:_alice.uniqueId identityKey:_bobIdentityKey];
    
    [aliceSession addPreKey:_bobPreKey ourBaseKey:_aliceBaseKeyPair];
    [bobSession addOurPreKey:_bobPreKey preKeyExchange:_alicePreKeyExchange];
    
    NSString *sendingMessage = @"Free Key!";
    NSData *sendingMessageData = [sendingMessage dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *encryptedMessage = [aliceSession encryptMessage:sendingMessageData];
    NSData *decryptedMessageData = [bobSession decryptMessage:encryptedMessage];
    XCTAssert([decryptedMessageData isEqual:sendingMessageData]);
    
    NSString *replyMessage = @"I got your message!";
    NSData *replyMessageData = [replyMessage dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *replyEncryptedMessage = [bobSession encryptMessage:replyMessageData];
    XCTAssert(replyEncryptedMessage.cipherText);
    NSData *decryptedReplyMessageData = [aliceSession decryptMessage:replyEncryptedMessage];
    XCTAssert([decryptedReplyMessageData isEqual:replyMessageData]);
    
    NSString *doubleReplyMessage = @"I got *your* message!";
    NSData *doubleReplyMessageData = [doubleReplyMessage dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *doubleReplyEncryptedMessage = [bobSession encryptMessage:doubleReplyMessageData];
    XCTAssert(doubleReplyEncryptedMessage.cipherText);
    NSData *doubleDecryptedReplyMessageData = [aliceSession decryptMessage:doubleReplyEncryptedMessage];
    XCTAssert([doubleDecryptedReplyMessageData isEqual:doubleReplyMessageData]);
}

@end