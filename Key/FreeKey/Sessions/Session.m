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
    _receiverIdentityPublicKey  = preKeyExchange.senderIdentityPublicKey.removeKeyType;
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
    _receiverIdentityPublicKey  = preKey.identityKey.removeKeyType;
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
    _senderRootChain = [[RootChain alloc]
                        initWithRootKey:sendRootKey chainKey:sendChainKey ratchetKeyPair:[Curve25519 generateKeyPair]];
    
    NSData *derivedReceiverMaterial = [HKDFKit deriveKey:masterReceiverKey.keyData info:info salt:salt outputSize:64];
    RootKey *receiveRootKey = [[RootKey alloc] initWithData:[derivedReceiverMaterial subdataWithRange:NSMakeRange(0, 32)]];
    ChainKey *receiveChainKey = [[ChainKey alloc] initWithData:[derivedReceiverMaterial subdataWithRange:NSMakeRange(32, 32)] index:0];
    _receiverRootChain = [[RootChain alloc] initWithRootKey:receiveRootKey chainKey:receiveChainKey ratchetKeyPair:nil];
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
    
    NSData *encryptedText = [AES_CBC encryptCBCMode:message withKey:messageKey.cipherKey withIV:messageKey.iv];
    
    EncryptedMessage *encryptedMessage = [[EncryptedMessage alloc] initWithMacKey:messageKey.macKey
                                                                senderIdentityKey:self.senderIdentityKey.publicKey.prependKeyType
                                                              receiverIdentityKey:self.receiverIdentityPublicKey.prependKeyType
                                                                 senderRatchetKey:senderRootChain.ratchetKey.prependKeyType
                                                                       cipherText:encryptedText
                                                                            index:senderChainKey.index
                                                                    previousIndex:self.previousIndex];
    [self setSenderRootChain:[senderRootChain iterateChainKey]];
    return encryptedMessage;
}

- (NSData *)decryptMessage:(EncryptedMessage *)encryptedMessage {
    SessionState *sessionState = [self processReceiverChain:encryptedMessage];
    NSData *decryptedText = [AES_CBC decryptCBCMode:encryptedMessage.cipherText
                                            withKey:sessionState.messageKey.cipherKey
                                             withIV:sessionState.messageKey.iv];
    
    // TODO: delete old message keys
    
    return decryptedText;
}

- (SessionState *)processReceiverChain:(EncryptedMessage *)encryptedMessage {
    int currentIndex = self.receiverRootChain.chainKey.index;
    SessionState *targetSession;
    while(encryptedMessage.index >= currentIndex) {
        if(encryptedMessage.index == currentIndex) {
            targetSession = [[SessionState alloc] initWithMessageKey:self.receiverRootChain.chainKey.messageKey index:self.receiverRootChain.chainKey.index];
        }else {
            SessionState *sessionState = [[SessionState alloc] initWithMessageKey:self.receiverRootChain.chainKey.messageKey index:self.receiverRootChain.chainKey.index];
            [self.previousSessionStates setObject:sessionState forKey:[[NSNumber alloc] initWithInt:currentIndex]];
            [self.receiverRootChain iterateChainKey];
        }
        currentIndex++;
    }
    
    if(encryptedMessage.previousIndex != self.senderRootChain.chainKey.index) {
        // TODO: Handle missing messages
    }
    return targetSession;
}

@end
