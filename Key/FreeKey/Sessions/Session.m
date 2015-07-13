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
#import "RootKey.h"
#import "ChainKey.h"
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
#import "Session+Serialize.h"
#import "KUser.h"

#define kReceivedSenderRatchets @"previousRatchets"

@implementation Session

- (instancetype)initWithSenderId:(NSString *)senderId receiverId:(NSString *)receiverId {
    self = [super init];
    if(self) {
        _senderId   = senderId;
        _receiverId = receiverId;
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
    
    NSLog(@"USER ID: %@", self.senderId);
    NSLog(@"SENDER ROOT CHAIN: %@", senderRootChain.rootKey.keyData);
    NSLog(@"RECEIVER ROOT CHAIN: %@", receiverRootChain.rootKey.keyData);
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
    
    NSLog(@"USER ID: %@", self.senderId);
    NSLog(@"SENDER ROOT CHAIN: %@", senderRootChain.rootKey.keyData);
    NSLog(@"RECEIVER ROOT CHAIN: %@", receiverRootChain.rootKey.keyData);
    
    [self ratchetSenderRootChain];
}


- (void)setupRootChainsFromKeyBundle:(SessionKeyBundle *)keyBundle {
    MasterKey *masterSenderKey = [[MasterKey alloc] initFromKeyBundle:keyBundle];
    MasterKey *masterReceiverKey = [[MasterKey alloc] initFromKeyBundle:[keyBundle oppositeBundle]];
    
    const char *HKDFDefaultSalt[4] = {0};
    NSData *salt = [NSData dataWithBytes:HKDFDefaultSalt length:sizeof(HKDFDefaultSalt)];
    NSData *info = [@"FreeKey" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *derivedSenderMaterial = [HKDFKit deriveKey:masterSenderKey.keyData info:info salt:salt outputSize:64];
    RootKey *sendRootKey = [[RootKey alloc] initWithData:[derivedSenderMaterial subdataWithRange:NSMakeRange(0, 32)]];
    ChainKey *sendChainKey =
    [[ChainKey alloc] initWithData:[derivedSenderMaterial subdataWithRange:NSMakeRange(32, 32)] index:0];
    RootChain *senderRootChain = [[RootChain alloc] initWithRootKey:sendRootKey chainKey:sendChainKey];
    [senderRootChain save];
    _senderChainId = senderRootChain.uniqueId;
    
    NSData *derivedReceiverMaterial = [HKDFKit deriveKey:masterReceiverKey.keyData info:info salt:salt outputSize:64];
    RootKey *receiveRootKey = [[RootKey alloc] initWithData:[derivedReceiverMaterial subdataWithRange:NSMakeRange(0, 32)]];
    ChainKey *receiveChainKey = [[ChainKey alloc] initWithData:[derivedReceiverMaterial subdataWithRange:NSMakeRange(32, 32)] index:0];
    RootChain *receiverRootChain = [[RootChain alloc] initWithRootKey:receiveRootKey chainKey:receiveChainKey];
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
    ChainKey  *senderChainKey  = senderRootChain.chainKey;
    MessageKey *messageKey     = senderChainKey.messageKey;
    
    NSData *senderRatchetKey   = senderRootChain.ourRatchetKeyPair.publicKey;
    NSData *encryptedText = [AES_CBC encryptCBCMode:message withKey:messageKey.cipherKey withIV:messageKey.iv];
    
    EncryptedMessage *encryptedMessage = [[EncryptedMessage alloc] initWithMacKey:messageKey.macKey
                                                                senderIdentityKey:self.sender.identityKey.publicKey
                                                              receiverIdentityKey:self.receiver.publicKey
                                                                 senderRatchetKey:senderRatchetKey
                                                                       cipherText:encryptedText
                                                                            index:senderChainKey.index
                                                                    previousIndex:self.previousIndex];
    
    RootChain *nextSenderRootChain = [senderRootChain iterateChainKey];
    [senderRootChain remove];
    [nextSenderRootChain save];
    self.senderChainId = nextSenderRootChain.uniqueId;
    [self save];
    
    return encryptedMessage;
}

- (NSData *)decryptMessage:(EncryptedMessage *)encryptedMessage {
    [self processReceiverChain:encryptedMessage];
    NSString *messageIndex = [NSString stringWithFormat:@"%d", encryptedMessage.index];
    SessionState *sessionState = [SessionState findByDictionary:@{@"senderRatchetKey" : encryptedMessage.senderRatchetKey, @"messageIndex" : messageIndex}];

    if(![HMAC verifyWithMac:[encryptedMessage mac]
          senderIdentityKey:self.receiver.publicKey
        receiverIdentityKey:self.sender.identityKey.publicKey
                     macKey:sessionState.messageKey.macKey
             serializedData:encryptedMessage.serializedData]) {
        NSLog(@"FAILED HMAC VERIFICATION");
    }
    
    NSData *decryptedData = [AES_CBC decryptCBCMode:encryptedMessage.cipherText
                                            withKey:sessionState.messageKey.cipherKey
                                             withIV:sessionState.messageKey.iv];
    return decryptedData;
}

- (void)processReceiverChain:(EncryptedMessage *)encryptedMessage {
    NSData *senderRatchetKey = encryptedMessage.senderRatchetKey;
    RootChain *receiverRootChain = [RootChain findById:self.receiverChainId];
    SessionState *previousState = [SessionState findByDictionary:@{@"senderRatchetKey" : senderRatchetKey}];
    if(!previousState) {
        if(encryptedMessage.previousIndex > receiverRootChain.chainKey.index) {
            [self sessionStatesForDesiredIndex:encryptedMessage.previousIndex senderRatchetKey:receiverRootChain.theirRatchetKey];
        }
    }
    [self ratchetRootChains:encryptedMessage.senderRatchetKey];
    [self sessionStatesForDesiredIndex:encryptedMessage.index senderRatchetKey:receiverRootChain.theirRatchetKey];
}

- (void)sessionStatesForDesiredIndex:(int)index senderRatchetKey:(NSData *)senderRatchetKey {
    RootChain *receiverRootChain = [RootChain findById:self.receiverChainId];
    while(index >= receiverRootChain.chainKey.index) {
        SessionState *sessionState = [[SessionState alloc] initWithMessageKey:receiverRootChain.chainKey.messageKey senderRatchetKey:senderRatchetKey messageIndex:receiverRootChain.chainKey.index sessionId:self.uniqueId];
        [sessionState save];
        
        RootChain *nextReceiverChain = [receiverRootChain iterateChainKey];
        [nextReceiverChain save];
        [receiverRootChain remove];
        [self setReceiverChainId:nextReceiverChain.uniqueId];
        receiverRootChain = nextReceiverChain;
    }
}

- (void)ratchetRootChains:(NSData *)theirEphemeral {
    if(![self alreadyReceivedEphemeral:theirEphemeral]) {
        [self ratchetReceiverRootChain:theirEphemeral];
        [self ratchetSenderRootChain];
    }
}

- (void)ratchetReceiverRootChain:(NSData *)theirEphemeral {
    RootChain *receiverRootChain = [RootChain findById:self.receiverChainId];
    ECKeyPair *ourEphemeral = receiverRootChain.ourRatchetKeyPair;
    RootChain *nextReceiverRootChain = [[RootChain alloc] iterateRootKeyWithTheirEphemeral:theirEphemeral ourEphemeral:ourEphemeral];
    [nextReceiverRootChain save];
    self.receiverChainId = nextReceiverRootChain.uniqueId;
    [self save];
}

- (void)ratchetSenderRootChain {
    RootChain *receiverRootChain = [RootChain findById:self.receiverChainId];
    NSData *theirEphemeral = receiverRootChain.theirRatchetKey;
    ECKeyPair *ourEphemeral = [Curve25519 generateKeyPair];
    RootChain *senderRootChain = [[RootChain alloc] iterateRootKeyWithTheirEphemeral:theirEphemeral ourEphemeral:ourEphemeral];
    [senderRootChain save];
    self.senderChainId = senderRootChain.uniqueId;
    
    receiverRootChain.ourRatchetKeyPair = ourEphemeral;
    [receiverRootChain save];
}

- (BOOL)alreadyReceivedEphemeral:(NSData *)theirEphemeral {
    return !([[SessionState findByDictionary:@{@"senderRatchetKey" : theirEphemeral}] isEqual:nil]);
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
