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

@interface SessionTests : XCTestCase

@end

@implementation SessionTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/**
 *  Testing session initialization with a basic PrekeyWhisperMessage
 */

- (void)testSimpleExchange {
    /*
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
    */
}

@end