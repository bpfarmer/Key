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

@implementation Session

- (instancetype)initWithReceiverId:(NSString *)receiverId identityKey:(IdentityKey *)identityKey{
    self = [super init];
    if(self) {
        _receiverId = receiverId;
        _senderIdentityKey = identityKey;
    }
    return self;
}

- (void)addOurPreKey:(PreKey *)ourPreKey preKeyExchange:(PreKeyExchange *)preKeyExchange  {
    _receiverIdentityPublicKey  = preKeyExchange.senderIdentityPublicKey;
    NSData *theirBaseKey = preKeyExchange.sentBaseKey;
    
    // TODO: some sort of verification of trust, signatures, etc
  
    SessionKeyBundle *keyBundle = [[SessionKeyBundle alloc] initWithTheirBaseKey:theirBaseKey
                                                                theirIdentityKey:preKeyExchange.senderIdentityPublicKey
                                                              ourIdentityKeyPair:self.senderIdentityKey.keyPair
                                                                      ourBaseKey:ourPreKey.baseKeyPair];
    [keyBundle setRolesWithFirstKey:theirBaseKey secondKey:ourPreKey.baseKeyPair.publicKey];
    [self setupRootChainsFromKeyBundle:keyBundle];
}

- (void)addPreKey:(PreKey *)preKey {
    _receiverIdentityPublicKey  = preKey.identityKey;
    _preKey = preKey;
    ECKeyPair *ourBaseKey = [Curve25519 generateKeyPair];
    _baseKeyPublic = ourBaseKey.publicKey;
    
    SessionKeyBundle *keyBundle = [[SessionKeyBundle alloc] initWithTheirBaseKey:preKey.signedPreKeyPublic
                                                               theirIdentityKey:self.receiverIdentityPublicKey
                                                             ourIdentityKeyPair:self.senderIdentityKey.keyPair
                                                                     ourBaseKey:ourBaseKey];
    [keyBundle setRolesWithFirstKey:ourBaseKey.publicKey secondKey:preKey.signedPreKeyPublic];
    [self setupRootChainsFromKeyBundle:keyBundle];
}


- (void)setupRootChainsFromKeyBundle:(SessionKeyBundle *)keyBundle {
    MasterKey *masterSenderKey = [[MasterKey alloc] initFromKeyBundle:keyBundle];
    MasterKey *masterReceiverKey = [[MasterKey alloc] initFromKeyBundle:[keyBundle oppositeBundle]];
    
    const char *HKDFDefaultSalt[4] = {0};
    NSData *salt = [NSData dataWithBytes:HKDFDefaultSalt length:sizeof(HKDFDefaultSalt)];
    NSData *info = [@"FreeKey" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *derivedSenderMaterial = [HKDFKit deriveKey:masterSenderKey.keyData info:info salt:salt outputSize:64];
    RootKey *sendRootKey = [[RootKey alloc] initWithData:[derivedSenderMaterial subdataWithRange:NSMakeRange(0, 32)]];
    ChainKey *sendChainKey = [[ChainKey alloc] initWithData:[derivedSenderMaterial subdataWithRange:NSMakeRange(32, 32)] index:0];
    RootChain *senderRootChain = [[RootChain alloc] initWithRootKey:sendRootKey chainKey:sendChainKey];
    [senderRootChain setRatchetKeyPair:keyBundle.ourBaseKey];
    _senderRootChain = senderRootChain;
    
    NSData *derivedReceiverMaterial = [HKDFKit deriveKey:masterReceiverKey.keyData info:info salt:salt outputSize:64];
    RootKey *receiveRootKey = [[RootKey alloc] initWithData:[derivedReceiverMaterial subdataWithRange:NSMakeRange(0, 32)]];
    ChainKey *receiveChainKey = [[ChainKey alloc] initWithData:[derivedReceiverMaterial subdataWithRange:NSMakeRange(32, 32)] index:0];
    _receiverRootChain = [[RootChain alloc] initWithRootKey:receiveRootKey chainKey:receiveChainKey];
}

- (PreKeyExchange *)preKeyExchange {
    PreKeyExchange *preKeyExchange = [[PreKeyExchange alloc] initWithSenderId:self.senderId
                                                                   receiverId:self.receiverId
                                                               targetPreKeyId:self.preKey.preKeyId
                                                         signedTargetPreKeyId:self.preKey.signedPreKeyId
                                                                  sentBaseKey:self.baseKeyPublic
                                                            sentSignedBaseKey:self.baseKeyPublic
                                                            senderIdentityPublicKey:self.senderIdentityKey.publicKey
                                                          receiverIdentityPublicKey:self.receiverIdentityPublicKey];
    return preKeyExchange;
}

- (void)verifyTheirPreKey:(PreKey *)theirPreKey theirIdentityKey:(IdentityKey *)theirIdentityKey {
    if (![theirIdentityKey isTrustedIdentityKey]) {
        // TODO: Build trust mechanism for identity keys
        //@throw [NSException exceptionWithName:UntrustedIdentityKeyException reason:@"Identity key is not valid" userInfo:@{}];
    }
    
    if (![Ed25519 verifySignature:theirPreKey.signedPreKeySignature publicKey:theirIdentityKey.publicKey data:theirPreKey.signedPreKeyPublic]) {
        //@throw [NSException exceptionWithName:InvalidKeyException reason:@"KeyIsNotValidlySigned" userInfo:nil];
    }
}

- (EncryptedMessage *)encryptMessage:(NSData *)message {
    RootChain *senderRootChain = self.senderRootChain;
    ChainKey  *senderChainKey  = senderRootChain.chainKey;
    MessageKey *messageKey     = senderChainKey.messageKey;
    NSData *senderRatchetKey   = senderRootChain.ratchetKeyPair.publicKey;
    
    NSData *encryptedText = [AES_CBC encryptCBCMode:message withKey:messageKey.cipherKey withIV:messageKey.iv];
    
    EncryptedMessage *encryptedMessage = [[EncryptedMessage alloc] initWithMacKey:messageKey.macKey
                                                                senderIdentityKey:self.senderIdentityKey.publicKey
                                                              receiverIdentityKey:self.receiverIdentityPublicKey
                                                                 senderRatchetKey:senderRatchetKey
                                                                       cipherText:encryptedText
                                                                            index:senderChainKey.index
                                                                    previousIndex:self.previousIndex];
    [self setSenderRootChain:[senderRootChain iterateChainKey]];
    return encryptedMessage;
}

- (NSData *)decryptMessage:(EncryptedMessage *)encryptedMessage {
    [self processReceiverChain:encryptedMessage];
    NSString *messageIndex = [NSString stringWithFormat:@"%d", encryptedMessage.index];
    SessionState *sessionState = [self sessionStateForSenderRatchetKey:encryptedMessage.senderRatchetKey index:messageIndex];
    // TODO: verify HMAC
    NSData *decryptedText = [AES_CBC decryptCBCMode:encryptedMessage.cipherText
                                            withKey:sessionState.messageKey.cipherKey
                                             withIV:sessionState.messageKey.iv];
    
    if(encryptedMessage.index != self.receiverRootChain.chainKey.index) {
        [self cleanupSessionState:sessionState];
    }
    
    return decryptedText;
}

- (void)processReceiverChain:(EncryptedMessage *)encryptedMessage {
    NSData *senderRatchetKey = encryptedMessage.senderRatchetKey;
    if(!self.previousSessionStates[senderRatchetKey]) {
        if(encryptedMessage.previousIndex >= self.receiverRootChain.chainKey.index) {
            [self sessionStatesForChainKey:self.receiverRootChain.chainKey
                              desiredIndex:encryptedMessage.previousIndex
                          senderRatchetKey:self.receiverRootChain.ratchetKey];
        }
        [self ratchetReceiverRootChain:senderRatchetKey];
        [self ratchetSenderRootChain];
    }
    [self sessionStatesForChainKey:self.receiverRootChain.chainKey
                      desiredIndex:encryptedMessage.index
                  senderRatchetKey:self.receiverRootChain.ratchetKey];
}

- (void)sessionStatesForChainKey:(ChainKey *)chainKey desiredIndex:(int)index senderRatchetKey:(NSData *)senderRatchetKey {
    int currentIndex = chainKey.index;
    int messageIndex = index;
    while(messageIndex >= currentIndex) {
        SessionState *sessionState = [[SessionState alloc] initWithMessageKey:chainKey.messageKey
                                                             senderRatchetKey:senderRatchetKey
                                                                        index:chainKey.index];
        
        NSMutableDictionary *ratchetKeyDictionary = [self.previousSessionStates objectForKey:senderRatchetKey];
        NSString *index = [NSString stringWithFormat:@"%d", self.receiverRootChain.chainKey.index];
        [ratchetKeyDictionary setObject:sessionState forKey:index];
        [self.receiverRootChain iterateChainKey];
        currentIndex++;
    }

}

- (void)ratchetReceiverRootChain:(NSData *)receiverRatchetKey {
    ECKeyPair *ourEphemeral;
    if(self.senderRootChain.ratchetKeyPair) {
        ourEphemeral = self.senderRootChain.ratchetKeyPair;
    }else {
        ourEphemeral = self.preKey.baseKeyPair;
    }
    self.receiverRootChain = [[RootChain alloc] iterateRootKeyWithTheirEphemeral:receiverRatchetKey
                                                                    ourEphemeral:ourEphemeral];
}

- (void)ratchetSenderRootChain {
    ECKeyPair *ourEphemeral = [Curve25519 generateKeyPair];
    NSData *theirEphemeral;
    if(self.receiverRootChain.ratchetKey) {
        theirEphemeral = self.receiverRootChain.ratchetKey;
    }else {
        theirEphemeral = self.preKey.signedPreKeyPublic;
    }
    self.senderRootChain = [[RootChain alloc] iterateRootKeyWithTheirEphemeral:theirEphemeral
                                                                  ourEphemeral:ourEphemeral];
}

- (SessionState *)sessionStateForSenderRatchetKey:(NSData *)senderRatchetKey index:(NSString *)index {
    SessionState *sessionState = self.previousSessionStates[senderRatchetKey][index];
    return sessionState;
}

- (void)cleanupSessionState:(SessionState *)sessionState {
    [self.previousSessionStates[sessionState.senderRatchetKey] removeObject:sessionState];
}

@end
