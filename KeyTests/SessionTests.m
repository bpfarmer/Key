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
#import "IdentityKey.h"
#import "AES_CBC.h"
#import "PreKeyExchange.h"
#import "KUser.h"
#import "FreeKeyTestExample.h"
#import "KStorageManager.h"
#import "MessageKey.h"
#import "FreeKeySessionManager.h"
#import "KStorageSchema.h"

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
    NSLog(@"DATABASE PATH: %@", [KStorageManager sharedManager].database.databasePath);
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/**
 * Testing Ratcheting Session
 */
- (void)testRatchetAgreement {
    Session *aliceSession = [[FreeKeySessionManager sharedManager] processNewKeyExchange:_bobPreKey localUser:_alice remoteUser:_bob];
    Session *bobSession = [[FreeKeySessionManager sharedManager] processNewKeyExchange:aliceSession.preKeyExchange localUser:_bob remoteUser:_alice];
    
    [aliceSession addPreKey:_bobPreKey ourBaseKey:_aliceBaseKeyPair];
    [bobSession addOurPreKey:_bobPreKey preKeyExchange:_alicePreKeyExchange];
    
    RootChain *aliceSRC = [RootChain findById:aliceSession.senderChainId];
    RootChain *aliceRRC = [RootChain findById:aliceSession.receiverChainId];
    RootChain *bobSRC   = [RootChain findById:bobSession.senderChainId];
    RootChain *bobRRC   = [RootChain findById:bobSession.receiverChainId];
    XCTAssert([aliceSRC.rootKey isEqual:bobRRC.rootKey]);
    XCTAssert([aliceRRC.theirRatchetKey isEqual:_bobPreKey.signedPreKeyPublic]);
    XCTAssert([bobRRC.theirRatchetKey isEqual:_alicePreKeyExchange.sentSignedBaseKey]);
    XCTAssert([aliceSRC.messageKey.cipherKey isEqual:bobRRC.messageKey.cipherKey]);
    
    NSString *sendingMessage = @"Free Key!";
    NSData *sendingMessageData = [sendingMessage dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *fromAlice = [aliceSession encryptMessage:sendingMessageData];
    [bobSession decryptMessage:fromAlice];
    
    aliceSRC = [RootChain findById:aliceSession.senderChainId];
    bobRRC = [RootChain findById:bobSession.receiverChainId];
    XCTAssert([aliceSRC.ourRatchetKeyPair.publicKey isEqual:bobRRC.theirRatchetKey]);
    XCTAssert([aliceSRC.rootKey isEqual:bobRRC.rootKey]);
    
    EncryptedMessage *fromBob = [bobSession encryptMessage:sendingMessageData];
    [aliceSession decryptMessage:fromBob];
    aliceRRC = [RootChain findById:aliceSession.receiverChainId];
    bobSRC = [RootChain findById:bobSession.senderChainId];
    XCTAssert([aliceRRC.theirRatchetKey isEqual:bobSRC.ourRatchetKeyPair.publicKey]);
    XCTAssert([aliceRRC.rootKey isEqual:bobSRC.rootKey]);
    [bobSession decryptMessage:[aliceSession encryptMessage:sendingMessageData]];
    XCTAssert([bobRRC.theirRatchetKey isEqual:aliceSRC.ourRatchetKeyPair.publicKey]);
    XCTAssert([aliceSRC.rootKey isEqual:bobRRC.rootKey]);
}

/**
 *  Testing simple exchange
 
 */

- (void)testSimpleExchange {
    Session *aliceSession = [[FreeKeySessionManager sharedManager] processNewKeyExchange:_bobPreKey localUser:_alice remoteUser:_bob];
    [_bobPreKey save];
    Session *bobSession = [[FreeKeySessionManager sharedManager] processNewKeyExchange:aliceSession.preKeyExchange localUser:_bob remoteUser:_alice];
    
    [aliceSession addPreKey:_bobPreKey ourBaseKey:_aliceBaseKeyPair];
    [bobSession addOurPreKey:_bobPreKey preKeyExchange:_alicePreKeyExchange];

    NSString *sendingMessage = @"Free Key!";
    NSData *sendingMessageData = [sendingMessage dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *encryptedMessage = [aliceSession encryptMessage:sendingMessageData];
    NSString *sendingMessage2 = @"Free Key Again!";
    NSData *sendingMessageData2 = [sendingMessage2 dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *encryptedMessage2 = [aliceSession encryptMessage:sendingMessageData2];
    
    NSLog(@"ENCRYPTED MESSAGE INDEX: %@", encryptedMessage2.index);
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
        NSLog(@"ENCRYPTED MESSAGE: %@", message);
        NSData *decryptedData = [aliceSession decryptMessage:message];
        NSLog(@"ODDLY WE'RE GETTING ONE OF THESE");
        XCTAssert([decryptedData isEqual:manyTestData]);
    }
}

- (void)testBobSendingFirst {
    Session *aliceSession = [[Session alloc] initWithSenderId:_alice.uniqueId receiverId:_bob.uniqueId];
    Session *bobSession   = [[Session alloc] initWithSenderId:_bob.uniqueId receiverId:_alice.uniqueId];
    
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