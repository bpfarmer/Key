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
#import "FreeKeyTestExample.h"

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
 * Testing Ratcheting Session
 */
- (void)testRatchetAgreement {
    Session *aliceSession = [[Session alloc] initWithReceiverId:_bob.uniqueId identityKey:_aliceIdentityKey];
    Session *bobSession   = [[Session alloc] initWithReceiverId:_alice.uniqueId identityKey:_bobIdentityKey];
    
    [aliceSession addPreKey:_bobPreKey ourBaseKey:_aliceBaseKeyPair];
    [bobSession addOurPreKey:_bobPreKey preKeyExchange:_alicePreKeyExchange];

    XCTAssert([aliceSession.receiverRootChain.theirRatchetKey isEqual:_bobPreKey.signedPreKeyPublic]);
    XCTAssert([bobSession.receiverRootChain.theirRatchetKey isEqual:_alicePreKeyExchange.sentSignedBaseKey]);
    XCTAssert([aliceSession.senderRootChain.chainKey.messageKey.cipherKey isEqual:bobSession.receiverRootChain.chainKey.messageKey.cipherKey]);
    
    NSString *sendingMessage = @"Free Key!";
    NSData *sendingMessageData = [sendingMessage dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *fromAlice = [aliceSession encryptMessage:sendingMessageData];
    [bobSession decryptMessage:fromAlice];
    XCTAssert([aliceSession.senderRootChain.ourRatchetKeyPair.publicKey isEqual:bobSession.receiverRootChain.theirRatchetKey]);
    XCTAssert([aliceSession.senderRootChain.chainKey.messageKey.cipherKey isEqual:bobSession.receiverRootChain.chainKey.messageKey.cipherKey]);
    
    EncryptedMessage *fromBob = [bobSession encryptMessage:sendingMessageData];
    [aliceSession decryptMessage:fromBob];
    XCTAssert([aliceSession.receiverRootChain.theirRatchetKey isEqual:bobSession.senderRootChain.ourRatchetKeyPair.publicKey]);
    XCTAssert([aliceSession.receiverRootChain.chainKey.messageKey.cipherKey isEqual:bobSession.senderRootChain.chainKey.messageKey.cipherKey]);
    [bobSession decryptMessage:[aliceSession encryptMessage:sendingMessageData]];
    XCTAssert([bobSession.receiverRootChain.theirRatchetKey isEqual:aliceSession.senderRootChain.ourRatchetKeyPair.publicKey]);
    XCTAssert([aliceSession.senderRootChain.chainKey.messageKey.cipherKey isEqual:bobSession.receiverRootChain.chainKey.messageKey.cipherKey]);
}

/**
 *  Testing simple exchange
 
 */

- (void)testSimpleExchange {
    Session *aliceSession = [[Session alloc] initWithReceiverId:_bob.uniqueId identityKey:_aliceIdentityKey];
    Session *bobSession   = [[Session alloc] initWithReceiverId:_alice.uniqueId identityKey:_bobIdentityKey];
    
    [aliceSession addPreKey:_bobPreKey ourBaseKey:_aliceBaseKeyPair];
    [bobSession addOurPreKey:_bobPreKey preKeyExchange:_alicePreKeyExchange];
    
    NSString *sendingMessage = @"Free Key!";
    NSData *sendingMessageData = [sendingMessage dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *encryptedMessage = [aliceSession encryptMessage:sendingMessageData];
    NSString *sendingMessage2 = @"Free Key Again!";
    NSData *sendingMessageData2 = [sendingMessage2 dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *encryptedMessage2 = [aliceSession encryptMessage:sendingMessageData2];
    
    NSLog(@"ENCRYPTED MESSAGE INDEX: %d", encryptedMessage2.index);
    NSData *decryptedMessageData = [bobSession decryptMessage:encryptedMessage];
    NSData *decryptedMessageData2 = [bobSession decryptMessage:encryptedMessage2];
    XCTAssert([decryptedMessageData2 isEqual:sendingMessageData2]);
    XCTAssert([decryptedMessageData isEqual:sendingMessageData]);
    
    NSString *replyMessage = @"I got your message!";
    NSData *replyMessageData = [replyMessage dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *replyEncryptedMessage = [bobSession encryptMessage:replyMessageData];
    NSString *replyMessage2 = @"I got your message! 2";
    NSData *replyMessageData2 = [replyMessage2 dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *replyEncryptedMessage2 = [bobSession encryptMessage:replyMessageData2];
    NSString *replyMessage3 = @"I got your message! 3";
    NSData *replyMessageData3 = [replyMessage3 dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *replyEncryptedMessage3 = [bobSession encryptMessage:replyMessageData3];

    NSData *decryptedReplyMessageData = [aliceSession decryptMessage:replyEncryptedMessage];
    XCTAssert([decryptedReplyMessageData isEqual:replyMessageData]);
    NSData *decryptedReplyMessageData2 = [aliceSession decryptMessage:replyEncryptedMessage2];
    XCTAssert([decryptedReplyMessageData2 isEqual:replyMessageData2]);
    NSData *decryptedReplyMessageData3 = [aliceSession decryptMessage:replyEncryptedMessage3];
    XCTAssert([decryptedReplyMessageData3 isEqual:replyMessageData3]);
    
    NSString *doubleReplyMessage = @"I got *your* message!";
    NSData *doubleReplyMessageData = [doubleReplyMessage dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *doubleReplyEncryptedMessage = [bobSession encryptMessage:doubleReplyMessageData];
    XCTAssert(doubleReplyEncryptedMessage.cipherText);
    NSData *doubleDecryptedReplyMessageData = [aliceSession decryptMessage:doubleReplyEncryptedMessage];
    XCTAssert([doubleDecryptedReplyMessageData isEqual:doubleReplyMessageData]);
    
    NSMutableArray *sentMessages = [[NSMutableArray alloc] init];
    NSString *manyTestString = @"I got your message!";
    NSData *manyTestData = [manyTestString dataUsingEncoding:NSUTF8StringEncoding];
    
    for (int i = 0; i < 100; i++) {
        EncryptedMessage *em = [bobSession encryptMessage:manyTestData];
        if(i % 2 == 0) {
            [sentMessages addObject:em];
        }
    }
    
    for(EncryptedMessage *message in sentMessages) {
        NSData *decryptedData = [aliceSession decryptMessage:message];
        XCTAssert([decryptedData isEqual:manyTestData]);
    }
}

- (void)testBobSendingFirst {
    Session *aliceSession = [[Session alloc] initWithReceiverId:_bob.uniqueId identityKey:_aliceIdentityKey];
    Session *bobSession   = [[Session alloc] initWithReceiverId:_alice.uniqueId identityKey:_bobIdentityKey];
    
    [aliceSession addPreKey:_bobPreKey ourBaseKey:_aliceBaseKeyPair];
    [bobSession addOurPreKey:_bobPreKey preKeyExchange:_alicePreKeyExchange];
    
    NSString *replyMessage = @"I got your message!";
    NSData *replyMessageData = [replyMessage dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *replyEncryptedMessage = [bobSession encryptMessage:replyMessageData];
    NSString *replyMessage2 = @"I got your message! 2";
    NSData *replyMessageData2 = [replyMessage2 dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *replyEncryptedMessage2 = [bobSession encryptMessage:replyMessageData2];
    NSString *replyMessage3 = @"I got your message! 3";
    NSData *replyMessageData3 = [replyMessage3 dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *replyEncryptedMessage3 = [bobSession encryptMessage:replyMessageData3];
    
    NSData *decryptedReplyMessageData = [aliceSession decryptMessage:replyEncryptedMessage];
    NSData *decryptedReplyMessageData2 = [aliceSession decryptMessage:replyEncryptedMessage2];
    NSData *decryptedReplyMessageData3 = [aliceSession decryptMessage:replyEncryptedMessage3];
    XCTAssert([decryptedReplyMessageData isEqual:replyMessageData]);
    XCTAssert([decryptedReplyMessageData2 isEqual:replyMessageData2]);
    XCTAssert([decryptedReplyMessageData3 isEqual:replyMessageData3]);
}

@end