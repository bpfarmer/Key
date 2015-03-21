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
    NSString *sendingMessage2 = @"Free Key Again!";
    NSData *sendingMessageData2 = [sendingMessage2 dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *encryptedMessage2 = [aliceSession encryptMessage:sendingMessageData2];
    
    NSLog(@"ENCRYPTED MESSAGE INDEX: %d", encryptedMessage2.index);
    NSData *decryptedMessageData2 = [bobSession decryptMessage:encryptedMessage2];
    NSData *decryptedMessageData = [bobSession decryptMessage:encryptedMessage];
    XCTAssert([decryptedMessageData isEqual:sendingMessageData]);
    XCTAssert([decryptedMessageData2 isEqual:sendingMessageData2]);
    
    NSString *replyMessage = @"I got your message!";
    NSData *replyMessageData = [replyMessage dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *replyEncryptedMessage = [bobSession encryptMessage:replyMessageData];
    NSString *replyMessage2 = @"I got your message!";
    NSData *replyMessageData2 = [replyMessage2 dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *replyEncryptedMessage2 = [bobSession encryptMessage:replyMessageData2];
    NSString *replyMessage3 = @"I got your message!";
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
}

- (void)testBobSendingFirst {
    Session *aliceSession = [[Session alloc] initWithReceiverId:_bob.uniqueId identityKey:_aliceIdentityKey];
    Session *bobSession   = [[Session alloc] initWithReceiverId:_alice.uniqueId identityKey:_bobIdentityKey];
    
    [aliceSession addPreKey:_bobPreKey ourBaseKey:_aliceBaseKeyPair];
    [bobSession addOurPreKey:_bobPreKey preKeyExchange:_alicePreKeyExchange];
    
    NSString *replyMessage = @"I got your message!";
    NSData *replyMessageData = [replyMessage dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *replyEncryptedMessage = [bobSession encryptMessage:replyMessageData];
    NSString *replyMessage2 = @"I got your message!";
    NSData *replyMessageData2 = [replyMessage2 dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *replyEncryptedMessage2 = [bobSession encryptMessage:replyMessageData2];
    NSString *replyMessage3 = @"I got your message!";
    NSData *replyMessageData3 = [replyMessage3 dataUsingEncoding:NSUTF8StringEncoding];
    EncryptedMessage *replyEncryptedMessage3 = [bobSession encryptMessage:replyMessageData3];
    
    NSData *decryptedReplyMessageData = [aliceSession decryptMessage:replyEncryptedMessage];
    XCTAssert([decryptedReplyMessageData isEqual:replyMessageData]);
    NSData *decryptedReplyMessageData2 = [aliceSession decryptMessage:replyEncryptedMessage2];
    XCTAssert([decryptedReplyMessageData2 isEqual:replyMessageData2]);
    NSData *decryptedReplyMessageData3 = [aliceSession decryptMessage:replyEncryptedMessage3];
    XCTAssert([decryptedReplyMessageData3 isEqual:replyMessageData3]);
}

@end