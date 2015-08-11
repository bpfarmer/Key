//
//  Session.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "Session.h"
#import "PreKey.h"
#import "NSData+keyVersionByte.h"
#import <25519/Ed25519.h>
#import <25519/Curve25519.h>
#import "HKDFKit.h"
#import "KeyDerivation.h"
#import "SessionKeyBundle.h"
#import "MasterKey.h"
#import "RootChain.h"
#import "EncryptedMessage.h"
#import "AES_CBC.h"
#import "MessageKey.h"
#import "SessionState.h"
#import "PreKeyExchange.h"
#import "PreKeyExchangeReceipt.h"
#import "HMAC.h"

#define kReceivedSenderRatchets @"previousRatchets"

@implementation Session

- (instancetype)initWithSenderDeviceId:(NSString *)senderDeviceId receiverDeviceId:(NSString *)receiverDeviceId {
    self = [super init];
    if(self) {
        _senderDeviceId   = senderDeviceId;
        _receiverDeviceId = receiverDeviceId;
        _previousIndex    = [[NSNumber alloc] initWithInt:0];
    }
    return self;
}

- (PreKeyExchange *)addSenderBaseKey:(ECKeyPair *)senderBaseKey senderIdentityKey:(ECKeyPair *)senderIdentityKey receiverPreKey:(PreKey *)receiverPreKey receiverPublicKey:(NSData *)receiverPublicKey {
    if(![Session verifySignature:receiverPreKey.signature publicKey:receiverPublicKey data:receiverPreKey.basePublicKey]) {
        NSLog(@"FAILED SIGNATURE VERIFICATION");
        // TODO: throw someething crazy!
    }

    _senderPublicKey    = senderIdentityKey.publicKey;
    _receiverPublicKey  = receiverPublicKey;
    
    SessionKeyBundle *keyBundle = [[SessionKeyBundle alloc] initWithSenderIdentityKey:senderIdentityKey senderBaseKey:senderBaseKey receiverBasePublicKey:receiverPreKey.basePublicKey receiverPublicKey:receiverPublicKey isAlice:NO];
    [keyBundle setRolesWithFirstKey:senderBaseKey.publicKey secondKey:receiverPreKey.basePublicKey];
    [self setupRootChainsFromKeyBundle:keyBundle];
    
    RootChain *senderRootChain          = [RootChain findById:self.senderChainId];
    senderRootChain.theirRatchetKey     = receiverPreKey.basePublicKey;
    senderRootChain.ourRatchetKeyPair   = senderBaseKey;
    [senderRootChain save];
    
    RootChain *receiverRootChain        = [RootChain findById:self.receiverChainId];
    receiverRootChain.theirRatchetKey   = receiverPreKey.basePublicKey;
    receiverRootChain.ourRatchetKeyPair = senderBaseKey;
    [receiverRootChain save];
    
    [self save];
    
    return [self preKeyExchangeWithPreKey:receiverPreKey basePublicKey:senderBaseKey.publicKey senderIdentityKey:senderIdentityKey receiverPublicKey:receiverPublicKey];
}

- (void)addSenderPreKey:(PreKey *)senderPreKey senderIdentityKey:(ECKeyPair *)senderIdentityKey receiverPreKeyExchange:(PreKeyExchange *)receiverPreKeyExchange receiverPublicKey:(NSData *)receiverPublicKey {
    _senderPublicKey    = senderIdentityKey.publicKey;
    _receiverPublicKey  = receiverPublicKey;
    
    SessionKeyBundle *keyBundle = [[SessionKeyBundle alloc] initWithSenderIdentityKey:senderIdentityKey
                                                                        senderBaseKey:senderPreKey.baseKeyPair
                                                                receiverBasePublicKey:receiverPreKeyExchange.basePublicKey
                                                                    receiverPublicKey:receiverPublicKey
                                                                              isAlice:YES];
    [keyBundle setRolesWithFirstKey:receiverPreKeyExchange.basePublicKey secondKey:senderPreKey.baseKeyPair.publicKey];
    [self setupRootChainsFromKeyBundle:keyBundle];
    
    RootChain *senderRootChain          = [RootChain findById:self.senderChainId];
    senderRootChain.theirRatchetKey     = receiverPreKeyExchange.basePublicKey;
    senderRootChain.ourRatchetKeyPair   = senderPreKey.baseKeyPair;
    [senderRootChain save];
    
    RootChain *receiverRootChain        = [RootChain findById:self.receiverChainId];
    receiverRootChain.theirRatchetKey   = receiverPreKeyExchange.basePublicKey;
    receiverRootChain.ourRatchetKeyPair = senderPreKey.baseKeyPair;
    [receiverRootChain save];
    
    [self ratchetSenderRootChain:receiverPreKeyExchange.basePublicKey];
    [self addReceivedRatchetKey:receiverPreKeyExchange.basePublicKey];
    
    [self save];
}


- (void)setupRootChainsFromKeyBundle:(SessionKeyBundle *)keyBundle {
    MasterKey *masterSenderKey = [[MasterKey alloc] initFromKeyBundle:keyBundle];
    MasterKey *masterReceiverKey = [[MasterKey alloc] initFromKeyBundle:[keyBundle oppositeBundle]];
    
    const char *HKDFDefaultSalt[4] = {0};
    NSData *salt = [NSData dataWithBytes:HKDFDefaultSalt length:sizeof(HKDFDefaultSalt)];
    NSData *info = [@"FreeKey" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *derivedSenderMaterial = [HKDFKit deriveKey:masterSenderKey.keyData info:info salt:salt outputSize:64];
    RootChain *senderRootChain = [[RootChain alloc] initWithRootKey:[derivedSenderMaterial subdataWithRange:NSMakeRange(0, 32)] chainKey:[derivedSenderMaterial subdataWithRange:NSMakeRange(32, 32)]];
    [senderRootChain save];
    _senderChainId = senderRootChain.uniqueId;
    
    NSData *derivedReceiverMaterial = [HKDFKit deriveKey:masterReceiverKey.keyData info:info salt:salt outputSize:64];
    RootChain *receiverRootChain = [[RootChain alloc] initWithRootKey:[derivedReceiverMaterial subdataWithRange:NSMakeRange(0, 32)] chainKey:[derivedReceiverMaterial subdataWithRange:NSMakeRange(32, 32)]];
    [receiverRootChain save];
    _receiverChainId = receiverRootChain.uniqueId;
    
    NSLog(@"INITIAL ROOT CHAIN SETUP");
    NSLog(@"SENDER ROOT CHAIN: %@", senderRootChain);
    NSLog(@"RECEIVER ROOT CHAIN: %@", receiverRootChain);
    
    [self save];
}

- (PreKeyExchange *)preKeyExchangeWithPreKey:(PreKey *)preKey basePublicKey:(NSData *)basePublicKey senderIdentityKey:(ECKeyPair *)senderIdentityKey receiverPublicKey:(NSData *)receiverPublicKey{
    return [[PreKeyExchange alloc] initWithSenderId:self.senderDeviceId
                                    senderPublicKey:senderIdentityKey.publicKey
                                      basePublicKey:basePublicKey
                                         receiverId:self.receiverDeviceId
                                           preKeyId:preKey.uniqueId];
}

- (EncryptedMessage *)encryptMessage:(NSData *)message {
    RootChain *senderRootChain = [RootChain findById:self.senderChainId];
    MessageKey *messageKey     = senderRootChain.messageKey;

    NSData *cipherText         = [AES_CBC encryptCBCMode:message withKey:messageKey.cipherKey withIV:messageKey.iv];
    NSMutableData *messageAndMac = [[NSMutableData alloc] init];
    NSData *mac = [HMAC generateMacWithMacKey:messageKey.macKey senderIdentityKey:self.senderPublicKey receiverIdentityKey:self.receiverPublicKey serializedData:cipherText];
    [messageAndMac appendData:cipherText];
    [messageAndMac appendData:mac];

    EncryptedMessage *encryptedMessage = [[EncryptedMessage alloc] initWithSenderId:self.senderDeviceId
                                                                         receiverId:self.receiverDeviceId
                                                                     serializedData:messageAndMac
                                                                   senderRatchetKey:senderRootChain.ourRatchetKeyPair.publicKey
                                                                              index:senderRootChain.index
                                                                      previousIndex:self.previousIndex];
    [senderRootChain iterateChainKey];
    
    NSLog(@"SENDER ROOT CHAIN ITERATED TO: %@", senderRootChain);
    return encryptedMessage;
}

- (NSData *)decryptMessage:(EncryptedMessage *)encryptedMessage {
    [self processReceiverChain:encryptedMessage];
    NSString *messageIndex = [NSString stringWithFormat:@"%@", encryptedMessage.index];
    SessionState *sessionState = [SessionState findByDictionary:@{@"senderRatchetKey" : encryptedMessage.senderRatchetKey, @"messageIndex" : messageIndex}];
    
    NSData *serializedData = encryptedMessage.serializedData;
    NSData *cipherText = [serializedData subdataWithRange:NSMakeRange(0, serializedData.length - 8)];
    NSData *mac        = [serializedData subdataWithRange:NSMakeRange(serializedData.length - 8, 8)];
    
    if(![Session verifyMac:mac remotePublicKey:self.receiverPublicKey localPublicKey:self.senderPublicKey macKey:sessionState.messageKey.macKey data:encryptedMessage.serializedData]) {
        NSLog(@"FAILED HMAC VERIFICATION"); //TODO: throw exception
        return nil;
    }else {
        NSData *decryptedData = [AES_CBC decryptCBCMode:cipherText
                                                withKey:sessionState.messageKey.cipherKey
                                                 withIV:sessionState.messageKey.iv];
        return decryptedData;
    }
}

- (void)processReceiverChain:(EncryptedMessage *)encryptedMessage {
    if([self isNewEphemeral:encryptedMessage.senderRatchetKey]) {
        NSLog(@"RECEIVING NEW EPHEMERAL KEY");
        [self saveSessionStatesUpToIndex:encryptedMessage.previousIndex];
        RootChain *senderRootChain = [RootChain findById:self.senderChainId];
        self.previousIndex = senderRootChain.index;
    }
    [self ratchetRootChains:encryptedMessage.senderRatchetKey];
    [self saveSessionStatesUpToIndex:encryptedMessage.index];
    [self save];
}

- (void)saveSessionStatesUpToIndex:(NSNumber *)index {
    RootChain *receiverRootChain = [RootChain findById:self.receiverChainId];
    while(index.intValue >= receiverRootChain.index.intValue) {
        SessionState *sessionState = [[SessionState alloc] initWithMessageKey:receiverRootChain.messageKey senderRatchetKey:receiverRootChain.theirRatchetKey messageIndex:receiverRootChain.index sessionId:self.uniqueId];
        [sessionState save];
        [receiverRootChain iterateChainKey];
        NSLog(@"ITERATING RECEIVER ROOT CHAIN: %@", receiverRootChain);
    }
}

- (void)ratchetRootChains:(NSData *)theirEphemeral {
    if([self isNewEphemeral:theirEphemeral]) {
        [self ratchetReceiverRootChain:theirEphemeral];
        [self ratchetSenderRootChain:theirEphemeral];
        [self addReceivedRatchetKey:theirEphemeral];
        NSLog(@"RATCHETING BOTH CHAINS");
        RootChain *senderRootChain = [RootChain findById:self.senderChainId];
        RootChain *receiverRootChain = [RootChain findById:self.receiverChainId];
        NSLog(@"SENDER ROOT CHAIN: %@", senderRootChain);
        NSLog(@"RECEIVER ROOT CHAIN: %@", receiverRootChain);
    }
}

- (void)ratchetReceiverRootChain:(NSData *)theirEphemeral {
    RootChain *receiverRootChain = [RootChain findById:self.receiverChainId];
    self.previousIndex = receiverRootChain.index;
    ECKeyPair *ourEphemeral = receiverRootChain.ourRatchetKeyPair;
    [receiverRootChain iterateRootKeyWithTheirEphemeral:theirEphemeral ourEphemeral:ourEphemeral];
}

- (void)ratchetSenderRootChain:(NSData *)theirEphemeral {
    RootChain *receiverRootChain = [RootChain findById:self.receiverChainId];
    RootChain *senderRootChain   = [RootChain findById:self.senderChainId];
    
    ECKeyPair *ourEphemeral = [Curve25519 generateKeyPair];
    receiverRootChain.theirRatchetKey = theirEphemeral;
    receiverRootChain.ourRatchetKeyPair = ourEphemeral;
    [receiverRootChain save];
    [senderRootChain iterateRootKeyWithTheirEphemeral:theirEphemeral ourEphemeral:ourEphemeral];
    senderRootChain.ourRatchetKeyPair = ourEphemeral;
    [senderRootChain save];
}

- (BOOL)isNewEphemeral:(NSData *)theirEphemeral {
    return ![self.receivedRatchetKeys containsObject:theirEphemeral];
}

- (void)addReceivedRatchetKey:(NSData *)theirEphemeral {
    NSLog(@"TRYING TO ADD NEW RATCHET KEY: %@", theirEphemeral);
    NSMutableArray *ratchetKeys = [[NSMutableArray alloc] initWithArray:self.receivedRatchetKeys];
    [ratchetKeys addObject:theirEphemeral];
    self.receivedRatchetKeys = [[NSArray alloc] initWithArray:ratchetKeys];
    [self save];
}

- (void)cleanupSessionState:(SessionState *)sessionState {
    [sessionState remove];
}

+ (BOOL)verifySignature:(NSData *)signature publicKey:(NSData *)publicKey data:(NSData *)data {
    return [Ed25519 verifySignature:signature publicKey:publicKey data:data];
}

+ (BOOL)verifyMac:(id)mac remotePublicKey:(NSData *)remotePublicKey localPublicKey:(NSData *)localPublicKey macKey:(NSData *)macKey data:(NSData *)data {
    return [HMAC verifyWithMac:mac senderIdentityKey:remotePublicKey receiverIdentityKey:localPublicKey macKey:macKey serializedData:data];
}

@end
