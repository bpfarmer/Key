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
#import "IdentityKey.h"
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
#import "KUser.h"
#import "KStorageManager.h"

#define kReceivedSenderRatchets @"previousRatchets"

@implementation Session

- (instancetype)initWithSenderId:(NSString *)senderId receiverId:(NSString *)receiverId {
    self = [super init];
    if(self) {
        _senderId   = senderId;
        _receiverId = receiverId;
        _previousIndex = [[NSNumber alloc] initWithInt:0];
    }
    return self;
}

- (void)addPreKey:(PreKey *)preKey ourBaseKey:(ECKeyPair *)ourBaseKey {
    _preKeyId = preKey.signedPreKeyId;
    _baseKeyPublic = ourBaseKey.publicKey;

    SessionKeyBundle *keyBundle = [[SessionKeyBundle alloc] initWithTheirBaseKey:preKey.signedPreKeyPublic
                                                                theirIdentityKey:preKey.identityKey
                                                              ourIdentityKeyPair:self.sender.identityKey.keyPair
                                                                      ourBaseKey:ourBaseKey
                                                                         isAlice:NO];
    
    [keyBundle setRolesWithFirstKey:ourBaseKey.publicKey secondKey:preKey.signedPreKeyPublic];
    [self setupRootChainsFromKeyBundle:keyBundle];
    
    RootChain *senderRootChain = [RootChain findById:self.senderChainId];
    senderRootChain.theirRatchetKey = preKey.signedPreKeyPublic;
    senderRootChain.ourRatchetKeyPair = ourBaseKey;
    [senderRootChain save];
    
    RootChain *receiverRootChain = [RootChain findById:self.receiverChainId];
    receiverRootChain.theirRatchetKey = preKey.signedPreKeyPublic;
    receiverRootChain.ourRatchetKeyPair = ourBaseKey;
    [receiverRootChain save];
}

- (void)addOurPreKey:(PreKey *)ourPreKey preKeyExchange:(PreKeyExchange *)preKeyExchange {
    // TODO: some sort of verification of trust, signatures, etc
    if(![Ed25519 verifySignature:preKeyExchange.baseKeySignature publicKey:preKeyExchange.senderIdentityPublicKey data:preKeyExchange.sentSignedBaseKey]) {
        NSLog(@"FAILED SIGNATURE VERIFICATION");
        // TODO: throw someething crazy!
    }
    
    NSData *theirBaseKey = preKeyExchange.sentSignedBaseKey;
    _preKeyId = ourPreKey.signedPreKeyId;
    
    SessionKeyBundle *keyBundle = [[SessionKeyBundle alloc] initWithTheirBaseKey:theirBaseKey
                                                                theirIdentityKey:preKeyExchange.senderIdentityPublicKey
                                                              ourIdentityKeyPair:self.sender.identityKey.keyPair
                                                                      ourBaseKey:ourPreKey.baseKeyPair
                                                                         isAlice:YES];
    
    [keyBundle setRolesWithFirstKey:theirBaseKey secondKey:ourPreKey.baseKeyPair.publicKey];
    [self setupRootChainsFromKeyBundle:keyBundle];
    
    RootChain *senderRootChain = [RootChain findById:self.senderChainId];
    senderRootChain.theirRatchetKey = theirBaseKey;
    senderRootChain.ourRatchetKeyPair = ourPreKey.baseKeyPair;
    [senderRootChain save];
    
    RootChain *receiverRootChain = [RootChain findById:self.receiverChainId];
    receiverRootChain.theirRatchetKey = theirBaseKey;
    receiverRootChain.ourRatchetKeyPair = ourPreKey.baseKeyPair;
    [receiverRootChain save];
    
    [self ratchetSenderRootChain:theirBaseKey];
    [self addReceivedRatchetKey:theirBaseKey];
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
    
    [self save];
}

- (PreKeyExchange *)preKeyExchange {
    NSData *signature = [Ed25519 sign:self.baseKeyPublic withKeyPair:self.sender.identityKey.keyPair];
    PreKeyExchange *preKeyExchange = [[PreKeyExchange alloc] initWithSenderId:self.senderId
                                                                   receiverId:self.receiverId
                                                         signedTargetPreKeyId:self.preKeyId
                                                            sentSignedBaseKey:self.baseKeyPublic
                                                      senderIdentityPublicKey:self.sender.identityKey.publicKey
                                                    receiverIdentityPublicKey:self.receiver.publicKey
                                                             baseKeySignature:signature];
    return preKeyExchange;
}

- (void)verifyTheirPreKey:(PreKey *)theirPreKey theirIdentityKey:(IdentityKey *)theirIdentityKey {
    if (![theirIdentityKey isTrustedIdentityKey]) {
        // TODO: Build trust mechanism for identity keys
        //@throw [NSException exceptionWithName:UntrustedIdentityKeyException reason:@"Identity key is not valid" userInfo:@{}];
    }
    
    if (![Ed25519 verifySignature:theirPreKey.signedPreKeySignature publicKey:theirIdentityKey.publicKey data:theirPreKey.signedPreKeyPublic]) {
        NSLog(@"FAILED SIGNATURE VERIFICATION");
        //@throw [NSException exceptionWithName:InvalidKeyException reason:@"KeyIsNotValidlySigned" userInfo:nil];
    }
}

- (EncryptedMessage *)encryptMessage:(NSData *)message {
    RootChain *senderRootChain = [RootChain findById:self.senderChainId];
    MessageKey *messageKey     = senderRootChain.messageKey;
    
    NSData *senderRatchetKey   = senderRootChain.ourRatchetKeyPair.publicKey;
    NSData *encryptedText = [AES_CBC encryptCBCMode:message withKey:messageKey.cipherKey withIV:messageKey.iv];
    NSLog(@"ENCRYPTING WITH KEY: %@", messageKey.cipherKey);
    EncryptedMessage *encryptedMessage = [[EncryptedMessage alloc] initWithMacKey:messageKey.macKey
                                                                senderIdentityKey:self.sender.identityKey.publicKey
                                                              receiverIdentityKey:self.receiver.publicKey
                                                                 senderRatchetKey:senderRatchetKey
                                                                       cipherText:encryptedText
                                                                            index:senderRootChain.index
                                                                    previousIndex:self.previousIndex];
    
    [senderRootChain iterateChainKey];
    
    return encryptedMessage;
}

- (NSData *)decryptMessage:(EncryptedMessage *)encryptedMessage {
    [self processReceiverChain:encryptedMessage];
    NSString *messageIndex = [NSString stringWithFormat:@"%@", encryptedMessage.index];
    SessionState *sessionState = [SessionState findByDictionary:@{@"senderRatchetKey" : encryptedMessage.senderRatchetKey, @"messageIndex" : messageIndex}];
    NSLog(@"SESSION STATE: %@", sessionState);
    if(![HMAC verifyWithMac:[encryptedMessage mac]
          senderIdentityKey:self.receiver.publicKey
        receiverIdentityKey:self.sender.identityKey.publicKey
                     macKey:sessionState.messageKey.macKey
             serializedData:encryptedMessage.serializedData]); //TODO: throw exception
    NSLog(@"DECRYPTING WITH KEY: %@", sessionState.messageKey.cipherKey);
    NSData *decryptedData = [AES_CBC decryptCBCMode:encryptedMessage.cipherText
                                            withKey:sessionState.messageKey.cipherKey
                                             withIV:sessionState.messageKey.iv];
    return decryptedData;
}

- (void)processReceiverChain:(EncryptedMessage *)encryptedMessage {
    if([self isNewEphemeral:encryptedMessage.senderRatchetKey]) {
        [self saveSessionStatesUpToIndex:encryptedMessage.previousIndex];
    }
    [self ratchetRootChains:encryptedMessage.senderRatchetKey];
    [self saveSessionStatesUpToIndex:encryptedMessage.index];
    self.previousIndex = encryptedMessage.index;
    [self save];
}

- (void)saveSessionStatesUpToIndex:(NSNumber *)index {
    RootChain *receiverRootChain = [RootChain findById:self.receiverChainId];
    while(index.intValue >= receiverRootChain.index.intValue) {
        SessionState *sessionState = [[SessionState alloc] initWithMessageKey:receiverRootChain.messageKey senderRatchetKey:receiverRootChain.theirRatchetKey messageIndex:receiverRootChain.index sessionId:self.uniqueId];
        [sessionState save];
        [receiverRootChain iterateChainKey];
    }
}

- (void)ratchetRootChains:(NSData *)theirEphemeral {
    if([self isNewEphemeral:theirEphemeral]) {
        [self ratchetReceiverRootChain:theirEphemeral];
        [self ratchetSenderRootChain:theirEphemeral];
        [self addReceivedRatchetKey:theirEphemeral];
    }
}

- (void)ratchetReceiverRootChain:(NSData *)theirEphemeral {
    RootChain *receiverRootChain = [RootChain findById:self.receiverChainId];
    self.previousIndex = receiverRootChain.index;
    ECKeyPair *ourEphemeral = receiverRootChain.ourRatchetKeyPair;
    [receiverRootChain iterateRootKeyWithTheirEphemeral:theirEphemeral ourEphemeral:ourEphemeral];
    NSLog(@"RATCHETING RRC FOR %@ WITH: %@ AND %@", self.senderId, theirEphemeral, ourEphemeral.publicKey);
    NSLog(@"NOW RRC FOR %@ IS: %@", self.senderId, receiverRootChain.rootKey);
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
    NSLog(@"RATCHETING SRC FOR %@ WITH: %@ AND %@", self.senderId, theirEphemeral, ourEphemeral.publicKey);
    NSLog(@"NOW SRC FOR %@ IS: %@", self.senderId, senderRootChain.rootKey);
}

- (BOOL)isNewEphemeral:(NSData *)theirEphemeral {
    return ![self.receivedRatchetKeys containsObject:theirEphemeral];
}

- (void)addReceivedRatchetKey:(NSData *)theirEphemeral {
    NSMutableArray *ratchetKeys = [[NSMutableArray alloc] initWithArray:self.receivedRatchetKeys];
    [ratchetKeys addObject:theirEphemeral];
    self.receivedRatchetKeys = [[NSArray alloc] initWithArray:ratchetKeys];
    [self save];
}

- (void)cleanupSessionState:(SessionState *)sessionState {
    [sessionState remove];
}

- (KUser *)sender {
    return [KUser findById:self.senderId];
}

- (KUser *)receiver {
    return [KUser findById:self.receiverId];
}

@end
