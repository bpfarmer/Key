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

- (void)testRetrievingPreKey {
    // NOTE: don't worry about serialization, storage or networking, we'll test that elsewhere
    NSString *BOB_RECIPIENT_ID   = @"+3828923892";
    NSString *ALICE_RECIPIENT_ID = @"alice@gmail.com";
    
    IdentityKey *aliceIdentityKey = [[IdentityKey alloc] initWithKeyPair:[Curve25519 generateKeyPair] userId:ALICE_RECIPIENT_ID];
    IdentityKey *bobIdentityKey = [[IdentityKey alloc] initWithKeyPair:[Curve25519 generateKeyPair] userId:BOB_RECIPIENT_ID];

    Session *aliceSession = [[Session alloc] initWithReceiverId:BOB_RECIPIENT_ID identityKey:aliceIdentityKey];
    
    ECKeyPair *bobPreKeyPair            = [Curve25519 generateKeyPair];
    ECKeyPair *bobSignedPreKeyPair      = [Curve25519 generateKeyPair];
    NSString  *bobUniqueId              = @"bobUniqueId";
    NSData    *bobSignedPreKeySignature = [Ed25519 sign:bobSignedPreKeyPair.publicKey withKeyPair:bobIdentityKey.keyPair];
    
    PreKey *bobPreKey = [[PreKey alloc] initWithUserId:bobUniqueId
                                              deviceId:@"1"
                                              preKeyId:@"31337"
                                          preKeyPublic:bobPreKeyPair.publicKey
                                    signedPreKeyPublic:bobSignedPreKeyPair.publicKey
                                        signedPreKeyId:@"22"
                                 signedPreKeySignature:bobSignedPreKeySignature
                                           identityKey:bobIdentityKey.publicKey
                                           baseKeyPair:bobSignedPreKeyPair];
    
    [aliceSession addPreKey:bobPreKey];
    
    RootChain *senderRootChain = aliceSession.senderRootChain;
    XCTAssertTrue(senderRootChain.rootKey);
    XCTAssertTrue(senderRootChain.chainKey);
    XCTAssertTrue(senderRootChain.chainKey.messageKey);
    
    NSString *sendingMessage = @"Free Key!";
    NSData *sendingMessageData = [sendingMessage dataUsingEncoding:NSUTF8StringEncoding];
    MessageKey *sendingMessageKey = senderRootChain.chainKey.messageKey;
    EncryptedMessage *encryptedMessage = [aliceSession encryptMessage:sendingMessageData];
    XCTAssertTrue(encryptedMessage.cipherText);
    
    Session *bobSession = [[Session alloc] initWithReceiverId:ALICE_RECIPIENT_ID identityKey:bobIdentityKey];
    [bobSession addOurPreKey:bobPreKey preKeyExchange:[aliceSession preKeyExchange]];
    
    RootChain *receiverRootChain = bobSession.receiverRootChain;
    MessageKey *receivingMessageKey = receiverRootChain.chainKey.messageKey;
    XCTAssertTrue(receiverRootChain.rootKey);
    XCTAssertTrue(receiverRootChain.chainKey);
    XCTAssertTrue(receiverRootChain.chainKey.messageKey);
    XCTAssertTrue([senderRootChain.rootKey.keyData isEqual:receiverRootChain.rootKey.keyData]);
    XCTAssertTrue([sendingMessageKey.cipherKey isEqual:receivingMessageKey.cipherKey]);
    XCTAssertTrue([sendingMessageKey.iv isEqual:receivingMessageKey.iv]);
    
    NSData *decryptedMessageData = [bobSession decryptMessage:encryptedMessage];
    XCTAssertTrue([decryptedMessageData isEqual:sendingMessageData]);
    
    NSString *replyMessage = @"I got your message!";
    NSData *replyMessageData = [replyMessage dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"MESSAGE INDEX: %d", bobSession.senderRootChain.chainKey.index);
    NSLog(@"MESSAGE KEYS: %@", bobSession.senderRootChain.chainKey.messageKey.cipherKey);
    EncryptedMessage *replyEncryptedMessage = [bobSession encryptMessage:replyMessageData];
    XCTAssertTrue(replyEncryptedMessage.cipherText);
    NSLog(@"ALICE MESSAGE INDEX: %d", aliceSession.receiverRootChain.chainKey.index);
    NSLog(@"ALICE MESSGE KEY: %@", aliceSession.receiverRootChain.chainKey.messageKey.cipherKey);
    NSData *decryptedReplyMessageData = [aliceSession decryptMessage:replyEncryptedMessage];
    XCTAssertTrue([decryptedReplyMessageData isEqual:replyMessageData]);
    
}

@end