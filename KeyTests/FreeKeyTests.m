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

@interface FreeKeyTests : XCTestCase

@end

@implementation FreeKeyTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPreKeyGeneration {
    KUser *user = [[KUser alloc] initWithUniqueId:@"12345"];
    FreeKey *testFreeKey = [FreeKey sharedManager];
    NSArray *preKeys = [testFreeKey generatePreKeysForUser:user];
    XCTAssert([preKeys count] == 100);
}

- (void)testPreKeySending {
    KUser *user = [[KUser alloc] initWithUniqueId:@"12345"];
    FreeKey *testFreeKey = [FreeKey sharedManager];
    NSArray *preKeys = [testFreeKey generatePreKeysForUser:user];
    [testFreeKey sendPreKeysToServer:preKeys];
    // TODO: how do we test reception?
}

- (void)testRetrieveUser {
    
}

- (void)testSessionCreationAndEncryption {
    
    NSString *bobId = @"bobUniqueId";
    NSString *aliceId = @"aliceUniqueId";
    
    KUser *alice = [[KUser alloc] initWithUniqueId:bobId];
    [alice setUsername:@"alice"];
    
    KUser *bob   = [[KUser alloc] initWithUniqueId:bobId];
    [bob setUsername:@"bob"];
    
    IdentityKey *aliceIdentityKey = [[IdentityKey alloc] initWithKeyPair:[Curve25519 generateKeyPair] userId:aliceId];
    [alice setIdentityKey:aliceIdentityKey];
    
    IdentityKey *bobIdentityKey = [[IdentityKey alloc] initWithKeyPair:[Curve25519 generateKeyPair] userId:bobId];
    [bob setPublicKey:bobIdentityKey.keyPair.publicKey];
    
    [alice save];
    [bob save];
    
    ECKeyPair *bobSignedPreKeyPair      = [Curve25519 generateKeyPair];
    NSData    *bobSignedPreKeySignature = [Ed25519 sign:bobSignedPreKeyPair.publicKey withKeyPair:bobIdentityKey.keyPair];
    
    NSDictionary *bobPreKeyDictionary = @{@"userId" : bobId,
                                          @"signedPreKeyId" : @"42",
                                          @"signedPreKeyPublic" : bobSignedPreKeyPair.publicKey,
                                          @"signedPreKeySignature" : bobSignedPreKeySignature,
                                          @"identityKey" : bobIdentityKey.publicKey};
    
    [[FreeKey sharedManager] createPreKeyFromRemoteDictionary:bobPreKeyDictionary];
    
    KMessage *message = [[KMessage alloc] initWithAuthorId:aliceId threadId:@"1" body:@"HERE"];
    
    [self measureBlock:^{
        [[FreeKey sharedManager] encryptObject:message localUser:alice recipientId:bobId];
    }];
    
    //XCTAssert(YES, @"Pass");
}

- (void)testResponseToFeed {
    [KStorageManager sharedManager];
    NSArray *preKeyExchangeRemoteKeys = [PreKeyExchange remoteKeys];
    NSArray *encryptedMessageRemoteKeys = [EncryptedMessage remoteKeys];
    
    KUser *recipient = [[KUser alloc] initWithUniqueId:@"1"];
    IdentityKey *recipientIdKey = [[IdentityKey alloc] initWithKeyPair:[Curve25519 generateKeyPair] userId:@"1"];
    [recipient setIdentityKey:recipientIdKey];
    [recipient setPublicKey:recipientIdKey.publicKey];
    [[FreeKey sharedManager] generatePreKeysForUser:recipient];
    [recipient save];
    
    KUser *sender = [[KUser alloc] initWithUniqueId:@"2"];
    IdentityKey *senderIdKey = [[IdentityKey alloc] initWithKeyPair:[Curve25519 generateKeyPair] userId:@"2"];
    [sender setIdentityKey:senderIdKey];
    [sender setPublicKey:senderIdKey.publicKey];
    [sender save];
    
    YapDatabaseConnection *connection = [[KStorageManager sharedManager] dbConnection];
    
    __block PreKey *preKey;
    
    [connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
       [transaction enumerateKeysAndObjectsInCollection:kOurPreKeyCollection usingBlock:^(NSString *key, id object, BOOL *stop) {
           preKey = (PreKey *)object;
       }];
    }];
    
    NSData *preKeySignature = [Ed25519 sign:preKey.signedPreKeyPublic withKeyPair:recipient.identityKey.keyPair];
    [[KStorageManager sharedManager] setObject:preKey forKey:recipient.uniqueId inCollection:kTheirPreKeyCollection];
    
    KMessage *message = [[KMessage alloc] initWithAuthorId:sender.uniqueId threadId:@"1" body:@"TEST OF MESSAGE ENCRYPTION"];
    EncryptedMessage *encryptedMessage = [[FreeKey sharedManager] encryptObject:message localUser:sender recipientId:recipient.uniqueId];
    
    NSDictionary *sampleFeed = @{@"status" : @"SUCCESS",
    kPreKeyExchangeRemoteAlias : @[@{preKeyExchangeRemoteKeys[0] : @"2",
                                 preKeyExchangeRemoteKeys[1] : @"1",
                                 preKeyExchangeRemoteKeys[2] : preKey.signedPreKeyId,
                                 preKeyExchangeRemoteKeys[3] : preKey.signedPreKeyPublic,
                                 preKeyExchangeRemoteKeys[4] : sender.identityKey.publicKey,
                                 preKeyExchangeRemoteKeys[5] : recipient.identityKey.publicKey,
                                 preKeyExchangeRemoteKeys[6] : preKeySignature}],
    kEncryptedMessageRemoteAlias :@[@{encryptedMessageRemoteKeys[0] : encryptedMessage.senderRatchetKey,
                                  encryptedMessageRemoteKeys[1] : sender.uniqueId,
                                  encryptedMessageRemoteKeys[2] : encryptedMessage.serializedData,
                                  encryptedMessageRemoteKeys[3] : [NSNumber numberWithInt:encryptedMessage.index],
                                  encryptedMessageRemoteKeys[4] : [NSNumber numberWithInt:encryptedMessage.previousIndex]}]};

    [[FreeKey sharedManager] receiveRemoteFeed:sampleFeed];
    
    PreKeyExchange *storedPKE = (PreKeyExchange *)[[KStorageManager sharedManager] objectForKey:sender.uniqueId inCollection:kPreKeyExchangeCollection];
    
    XCTAssert(storedPKE.signedTargetPreKeyId);
    
    __block EncryptedMessage *storedEncryptedMessage;
    
    [connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateKeysAndObjectsInCollection:kTheirEncryptedMessageCollection usingBlock:^(NSString *key, id object, BOOL *stop) {
            storedEncryptedMessage = (EncryptedMessage *)object;
        }];
    }];
    
    KMessage *decryptedMessage = (KMessage *)[[FreeKey sharedManager] decryptEncryptedMessage:storedEncryptedMessage localUser:recipient senderId:sender.uniqueId];
    
    XCTAssert([decryptedMessage.body isEqualToString:message.body]);
}


- (void)testPerformanceSetupPreKeys {
    KUser *user = [[KUser alloc] initWithUniqueId:@"1"];
    [self measureBlock:^{
        FreeKey *freeKey = [[FreeKey alloc] init];
        [freeKey generatePreKeysForUser:user];
    }];
}

@end
