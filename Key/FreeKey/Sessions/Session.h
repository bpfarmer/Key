//
//  Session.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KDatabaseObject.h"

@class PreKey;
@class EncryptedMessage;
@class PreKeyExchange;
@class ECKeyPair;

@interface Session : KDatabaseObject

@property (nonatomic, readonly)  NSString *senderDeviceId;
@property (nonatomic, readonly)  NSData   *senderPublicKey;
@property (nonatomic, readwrite) NSString *senderChainId;
@property (nonatomic, readonly)  NSString *receiverDeviceId;
@property (nonatomic, readonly)  NSData   *receiverPublicKey;
@property (nonatomic, readwrite) NSString *receiverChainId;
@property (nonatomic, readwrite) NSNumber *previousIndex;
@property (nonatomic, readwrite) NSArray  *receivedRatchetKeys;

- (instancetype)initWithSenderDeviceId:(NSString *)senderDeviceId receiverDeviceId:(NSString *)receiverDeviceId;

- (void)addSenderPreKey:(PreKey *)senderPreKey senderIdentityKey:(ECKeyPair *)senderIdentityKey receiverPreKeyExchange:(PreKeyExchange *)receiverPreKeyExchange receiverPublicKey:(NSData *)receiverPublicKey;
- (PreKeyExchange *)addSenderBaseKey:(ECKeyPair *)senderBaseKey senderIdentityKey:(ECKeyPair *)senderIdentityKey receiverPreKey:(PreKey *)receiverPreKey receiverPublicKey:(NSData *)receiverPublicKey;

- (EncryptedMessage *)encryptMessage:(NSData *)message;
- (NSData *)decryptMessage:(EncryptedMessage *)encryptedMessage;

+ (BOOL)verifySignature:(NSData *)signature publicKey:(NSData *)publicKey data:(NSData *)data;
+ (BOOL)verifyMac:mac remotePublicKey:(NSData *)remotePublicKey localPublicKey:(NSData *)localPublicKey macKey:(NSData *)macKey data:(NSData *)data;

@end
