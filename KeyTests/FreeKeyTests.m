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
#import "PreKeyExchange.h"
#import "EncryptedMessage.h"
#import "NSData+Base64.h"
#import "RootChain.h"
#import "ChainKey.h"
#import "MessageKey.h"
#import "FreeKeySessionManager.h"
#import "FreeKeyNetworkManager.h"
#import "FreeKeyTestExample.h"
#import "KThread.h"
#import "HttpManager.h"
#import "FreeKeyResponseHandler.h"

@interface FreeKeyTests : XCTestCase

@property KUser *alice;
@property KUser *bob;
@property IdentityKey *aliceIdentityKey;
@property IdentityKey *bobIdentityKey;
@property ECKeyPair *aliceBaseKeyPair;
@property ECKeyPair *bobBaseKeyPair;
@property PreKey *bobPreKey;
@property PreKeyExchange *alicePreKeyExchange;
@property Session *aliceSession;
@property Session *bobSession;

@end

@implementation FreeKeyTests

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
    _aliceSession     = [example aliceSession];
    _bobSession       = [example bobSession];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSendAndDecryptThread {
    KThread *sentThread = [[KThread alloc] initWithUsers:@[_alice, _bob]];
    EncryptedMessage *message = [FreeKey encryptObject:sentThread session:_aliceSession];
    KThread *receivedThread = (KThread *)[FreeKey decryptEncryptedMessage:message session:_bobSession];
    XCTAssert([sentThread.uniqueId isEqual:receivedThread.uniqueId]);
}

- (void)testSendAndDecryptMessage {
    KThread *sentThread = [[KThread alloc] initWithUsers:@[_alice, _bob]];
    KMessage *sentMessage = [[KMessage alloc] initWithAuthorId:_alice.uniqueId threadId:sentThread.uniqueId body:@"Great Big Test"];
    EncryptedMessage *encryptedThread = [FreeKey encryptObject:sentThread session:_aliceSession];
    EncryptedMessage *encryptedMessage = [FreeKey encryptObject:sentMessage session:_aliceSession];
    
    KThread *receivedThread = (KThread *)[FreeKey decryptEncryptedMessage:encryptedThread session:_bobSession];
    KMessage *receivedMessage = (KMessage *)[FreeKey decryptEncryptedMessage:encryptedMessage session:_bobSession];
    
    XCTAssert([sentThread.uniqueId isEqualToString:receivedThread.uniqueId]);
    XCTAssert([sentMessage.uniqueId isEqualToString:receivedMessage.uniqueId]);
    XCTAssert([sentMessage.threadId isEqualToString:receivedMessage.threadId]);
}

- (void)testSendAndDecryptMessageInBase64 {
    KThread *sentThread = [[KThread alloc] initWithUsers:@[_alice, _bob]];
    KMessage *sentMessage = [[KMessage alloc] initWithAuthorId:_alice.uniqueId threadId:sentThread.uniqueId body:@"Great Big Test"];
    EncryptedMessage *encryptedMessage = [FreeKey encryptObject:sentMessage session:_aliceSession];
    NSMutableDictionary *encryptedMessageDictionary = [[NSMutableDictionary alloc] initWithDictionary:[encryptedMessage dictionaryWithValuesForKeys:[EncryptedMessage remoteKeys]]];
    NSArray *remoteKeys = [EncryptedMessage remoteKeys];
    encryptedMessageDictionary[remoteKeys[0]] = [encryptedMessageDictionary[remoteKeys[0]] base64EncodedString];
    encryptedMessageDictionary[remoteKeys[3]] = [encryptedMessageDictionary[remoteKeys[3]] base64EncodedString];
    NSDictionary *decodedMessageDictionary = [[HttpManager sharedManager] base64DecodedDictionary:encryptedMessageDictionary];
    EncryptedMessage *receivedEncryptedMessage = [FreeKeyResponseHandler createEncryptedMessageFromRemoteDictionary:decodedMessageDictionary];
    KMessage *receivedMessage = (KMessage *)[FreeKey decryptEncryptedMessage:receivedEncryptedMessage session:_bobSession];
    XCTAssert([sentMessage.body isEqualToString:receivedMessage.body]);
}


@end
