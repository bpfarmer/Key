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
#import "PreKeyExchange.h"
#import "KStorageManager.h"
#import "MessageKey.h"
#import "KStorageSchema.h"

@interface SessionTests : XCTestCase

@end

@implementation SessionTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInit {
    NSString *senderDeviceId = @"1_1";
    NSString *receiverDeviceId = @"2_2";
    Session *session = [[Session alloc] initWithSenderDeviceId:senderDeviceId receiverDeviceId:receiverDeviceId];
    XCTAssert([session.senderDeviceId isEqualToString:senderDeviceId]);
    XCTAssert([session.receiverDeviceId isEqualToString:receiverDeviceId]);
    XCTAssert(session.previousIndex.integerValue == 0);
}

- (void)testPreKeySignature {
    ECKeyPair *receiverBaseKey     = [Curve25519 generateKeyPair];
    ECKeyPair *receiverIdentityKey = [Curve25519 generateKeyPair];
    NSString *receiverDeviceId     = @"2_2";
    
    void *bytes = malloc(64);
    PreKey *unsignedPreKey   = [[PreKey alloc] initWithUniqueId:@"1" userId:receiverDeviceId basePublicKey:receiverBaseKey.publicKey signature:[NSData dataWithBytes:bytes length:64] publicKey:receiverIdentityKey.publicKey baseKeyPair:receiverBaseKey];
    XCTAssert(![Session verifySignature:unsignedPreKey.signature publicKey:receiverIdentityKey.publicKey data:unsignedPreKey.basePublicKey]);
    
    NSData *signature = [Ed25519 sign:receiverBaseKey.publicKey withKeyPair:receiverIdentityKey];
    PreKey *signedPreKey   = [[PreKey alloc] initWithUniqueId:@"1" userId:receiverDeviceId basePublicKey:receiverBaseKey.publicKey signature:signature publicKey:receiverIdentityKey.publicKey baseKeyPair:receiverBaseKey];
    XCTAssert([Session verifySignature:signedPreKey.signature publicKey:receiverIdentityKey.publicKey data:signedPreKey.basePublicKey]);
}

- (void)testAddPreKey {
    ECKeyPair *senderBaseKey       = [Curve25519 generateKeyPair];
    ECKeyPair *senderIdentityKey   = [Curve25519 generateKeyPair];
    NSString *senderDeviceId       = @"1_1";
    ECKeyPair *receiverBaseKey     = [Curve25519 generateKeyPair];
    ECKeyPair *receiverIdentityKey = [Curve25519 generateKeyPair];
    NSString *receiverDeviceId     = @"2_2";
    
    NSData *signature = [Ed25519 sign:receiverBaseKey.publicKey withKeyPair:receiverIdentityKey];
    PreKey *signedPreKey   = [[PreKey alloc] initWithUniqueId:@"1" userId:receiverDeviceId basePublicKey:receiverBaseKey.publicKey signature:signature publicKey:receiverIdentityKey.publicKey baseKeyPair:receiverBaseKey];
    XCTAssert([Session verifySignature:signedPreKey.signature publicKey:receiverIdentityKey.publicKey data:signedPreKey.basePublicKey]);
    
    Session *session = [[Session alloc] initWithSenderDeviceId:senderDeviceId receiverDeviceId:receiverDeviceId];
    PreKeyExchange *preKeyExchange = [session addSenderBaseKey:senderBaseKey senderIdentityKey:senderIdentityKey receiverPreKey:signedPreKey receiverPublicKey:receiverIdentityKey.publicKey];
    
    XCTAssert(session.senderChainId);
    XCTAssert(session.receiverChainId);
    XCTAssert(preKeyExchange.senderId);
    XCTAssert(preKeyExchange.receiverId);
    XCTAssert(preKeyExchange.basePublicKey);
    XCTAssert([preKeyExchange.preKeyId isEqualToString:signedPreKey.uniqueId]);
    XCTAssert(preKeyExchange.signature);
    XCTAssert([Session verifySignature:preKeyExchange.signature publicKey:preKeyExchange.senderPublicKey data:preKeyExchange.basePublicKey]);
}

- (void)testAddPreKeyExchange {
    ECKeyPair *senderBaseKey       = [Curve25519 generateKeyPair];
    ECKeyPair *senderIdentityKey   = [Curve25519 generateKeyPair];
    NSString *senderDeviceId       = @"1_1";
    ECKeyPair *receiverBaseKey     = [Curve25519 generateKeyPair];
    ECKeyPair *receiverIdentityKey = [Curve25519 generateKeyPair];
    NSString *receiverDeviceId     = @"2_2";
    
    NSData *signature = [Ed25519 sign:receiverBaseKey.publicKey withKeyPair:receiverIdentityKey];
    PreKey *signedPreKey   = [[PreKey alloc] initWithUniqueId:@"1" userId:receiverDeviceId basePublicKey:receiverBaseKey.publicKey signature:signature publicKey:receiverIdentityKey.publicKey baseKeyPair:receiverBaseKey];
    
    Session *session = [[Session alloc] initWithSenderDeviceId:senderDeviceId receiverDeviceId:receiverDeviceId];
    PreKeyExchange *preKeyExchange = [session addSenderBaseKey:senderBaseKey senderIdentityKey:senderIdentityKey receiverPreKey:signedPreKey receiverPublicKey:receiverIdentityKey.publicKey];
    
    Session *oppositeSession = [[Session alloc] initWithSenderDeviceId:receiverDeviceId receiverDeviceId:senderDeviceId];
    [oppositeSession addSenderPreKey:signedPreKey senderIdentityKey:receiverIdentityKey receiverPreKeyExchange:preKeyExchange receiverPublicKey:senderIdentityKey.publicKey];
    XCTAssert(oppositeSession.senderChainId);
    XCTAssert(oppositeSession.receiverChainId);
    
    RootChain *sessionSenderChain    = [RootChain findById:session.senderChainId];
    NSLog(@"%@", sessionSenderChain);
    RootChain *oppositeReceiverChain = [RootChain findById:oppositeSession.receiverChainId];
    NSLog(@"%@", oppositeReceiverChain);
    XCTAssert([sessionSenderChain.rootKey isEqualToData:oppositeReceiverChain.rootKey]);
}

- (void)testEncryptionAndDecryption {
    ECKeyPair *senderBaseKey       = [Curve25519 generateKeyPair];
    ECKeyPair *senderIdentityKey   = [Curve25519 generateKeyPair];
    NSString *senderDeviceId       = @"1_1";
    ECKeyPair *receiverBaseKey     = [Curve25519 generateKeyPair];
    ECKeyPair *receiverIdentityKey = [Curve25519 generateKeyPair];
    NSString *receiverDeviceId     = @"2_2";
    
    NSData *signature = [Ed25519 sign:receiverBaseKey.publicKey withKeyPair:receiverIdentityKey];
    PreKey *signedPreKey   = [[PreKey alloc] initWithUniqueId:@"1" userId:receiverDeviceId basePublicKey:receiverBaseKey.publicKey signature:signature publicKey:receiverIdentityKey.publicKey baseKeyPair:receiverBaseKey];
    
    Session *session = [[Session alloc] initWithSenderDeviceId:senderDeviceId receiverDeviceId:receiverDeviceId];
    PreKeyExchange *preKeyExchange = [session addSenderBaseKey:senderBaseKey senderIdentityKey:senderIdentityKey receiverPreKey:signedPreKey receiverPublicKey:receiverIdentityKey.publicKey];
    
    Session *oppositeSession = [[Session alloc] initWithSenderDeviceId:receiverDeviceId receiverDeviceId:senderDeviceId];
    [oppositeSession addSenderPreKey:signedPreKey senderIdentityKey:receiverIdentityKey receiverPreKeyExchange:preKeyExchange receiverPublicKey:senderIdentityKey.publicKey];
    
    NSData *message1 = [@"message1" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *message2 = [@"message2" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *message3 = [@"message3" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *message4 = [@"message4" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *message5 = [@"message5" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *message6 = [@"message6" dataUsingEncoding:NSUTF8StringEncoding];
    
    XCTAssert([[oppositeSession decryptMessage:[session encryptMessage:message5]] isEqualToData:message5]);
    XCTAssert([[oppositeSession decryptMessage:[session encryptMessage:message6]] isEqualToData:message6]);
    XCTAssert([[oppositeSession decryptMessage:[session encryptMessage:message1]] isEqualToData:message1]);
    XCTAssert([[oppositeSession decryptMessage:[session encryptMessage:message2]] isEqualToData:message2]);
    XCTAssert([[oppositeSession decryptMessage:[session encryptMessage:message4]] isEqualToData:message4]);
    XCTAssert([[oppositeSession decryptMessage:[session encryptMessage:message3]] isEqualToData:message3]);
    
    XCTAssert([[session decryptMessage:[oppositeSession encryptMessage:message2]] isEqualToData:message2]);
    XCTAssert([[session decryptMessage:[oppositeSession encryptMessage:message4]] isEqualToData:message4]);
    XCTAssert([[session decryptMessage:[oppositeSession encryptMessage:message6]] isEqualToData:message6]);
    XCTAssert([[session decryptMessage:[oppositeSession encryptMessage:message3]] isEqualToData:message3]);
    XCTAssert([[session decryptMessage:[oppositeSession encryptMessage:message5]] isEqualToData:message5]);
    XCTAssert([[session decryptMessage:[oppositeSession encryptMessage:message1]] isEqualToData:message1]);
    
    XCTAssert([[oppositeSession decryptMessage:[session encryptMessage:message1]] isEqualToData:message1]);
    XCTAssert([[oppositeSession decryptMessage:[session encryptMessage:message2]] isEqualToData:message2]);
    
    XCTAssert([[session decryptMessage:[oppositeSession encryptMessage:message2]] isEqualToData:message2]);
    XCTAssert([[session decryptMessage:[oppositeSession encryptMessage:message4]] isEqualToData:message4]);
    
    XCTAssert([[oppositeSession decryptMessage:[session encryptMessage:message4]] isEqualToData:message4]);
    XCTAssert([[oppositeSession decryptMessage:[session encryptMessage:message3]] isEqualToData:message3]);
}

@end