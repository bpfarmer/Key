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

#define kReceivedSenderRatchets @"previousRatchets"

@implementation Session

- (instancetype)initWithReceiverId:(NSString *)receiverId identityKey:(IdentityKey *)identityKey{
    self = [super init];
    if(self) {
        _receiverId = receiverId;
        _senderIdentityKey = identityKey;
    }
    return self;
}

- (instancetype)initWithSenderId:(NSString *)senderId
                      receiverId:(NSString *)receiverId
                          preKey:(PreKey *)preKey
                   baseKeyPublic:(NSData *)baseKeyPublic
               senderIdentityKey:(IdentityKey *)senderIdentityKey
       receiverIdentityPublicKey:(NSData *)receiverIdentityPublicKey
                 senderRootChain:(RootChain *)senderRootChain
               receiverRootChain:(RootChain *)receiverRootChain
                   previousIndex:(int)previousIndex
           previousSessionStates:(NSDictionary *)previousSessionStates {
    self = [super init];
    if(self) {
        _senderId = senderId;
        _receiverId = receiverId;
        _preKey = preKey;
        _baseKeyPublic = baseKeyPublic;
        _senderIdentityKey = senderIdentityKey;
        _receiverIdentityPublicKey = receiverIdentityPublicKey;
        _senderRootChain = senderRootChain;
        _receiverRootChain = receiverRootChain;
        _previousIndex = previousIndex;
        _previousSessionStates = previousSessionStates;
    }
    return self;
}

- (void)addPreKey:(PreKey *)preKey ourBaseKey:(ECKeyPair *)ourBaseKey {
    _receiverIdentityPublicKey  = preKey.identityKey;
    _preKey = preKey;
    _baseKeyPublic = ourBaseKey.publicKey;
    
    SessionKeyBundle *keyBundle = [[SessionKeyBundle alloc] initWithTheirBaseKey:preKey.signedPreKeyPublic
                                                                theirIdentityKey:self.receiverIdentityPublicKey
                                                              ourIdentityKeyPair:self.senderIdentityKey.keyPair
                                                                      ourBaseKey:ourBaseKey
                                                                         isAlice:NO];
    
    [keyBundle setRolesWithFirstKey:ourBaseKey.publicKey secondKey:preKey.signedPreKeyPublic];
    [self setupRootChainsFromKeyBundle:keyBundle];
    
    
    self.senderRootChain.theirRatchetKey = preKey.signedPreKeyPublic;
    self.senderRootChain.ourRatchetKeyPair = ourBaseKey;
    self.receiverRootChain.theirRatchetKey = preKey.signedPreKeyPublic;
    self.receiverRootChain.ourRatchetKeyPair = ourBaseKey;
}

- (void)addOurPreKey:(PreKey *)ourPreKey preKeyExchange:(PreKeyExchange *)preKeyExchange  {
    _receiverIdentityPublicKey  = preKeyExchange.senderIdentityPublicKey;
    NSData *theirBaseKey = preKeyExchange.sentSignedBaseKey;
    
    // TODO: some sort of verification of trust, signatures, etc
    if(![Ed25519 verifySignature:preKeyExchange.baseKeySignature publicKey:preKeyExchange.senderIdentityPublicKey data:preKeyExchange.sentSignedBaseKey]) {
        NSLog(@"FAILED SIGNATURE VERIFICATION");
        // TODO: throw someething crazy!
    }

    SessionKeyBundle *keyBundle = [[SessionKeyBundle alloc] initWithTheirBaseKey:theirBaseKey
                                                                theirIdentityKey:preKeyExchange.senderIdentityPublicKey
                                                              ourIdentityKeyPair:self.senderIdentityKey.keyPair
                                                                      ourBaseKey:ourPreKey.baseKeyPair
                                                                         isAlice:YES];
    
    [keyBundle setRolesWithFirstKey:theirBaseKey secondKey:ourPreKey.baseKeyPair.publicKey];
    [self setupRootChainsFromKeyBundle:keyBundle];
    self.previousSessionStates = @{kReceivedSenderRatchets : @[theirBaseKey]};
    
    self.receiverRootChain.theirRatchetKey = theirBaseKey;
    self.receiverRootChain.ourRatchetKeyPair = ourPreKey.baseKeyPair;
    self.senderRootChain.theirRatchetKey = theirBaseKey;
    self.senderRootChain.ourRatchetKeyPair = ourPreKey.baseKeyPair;
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
    _senderRootChain = [[RootChain alloc] initWithRootKey:sendRootKey chainKey:sendChainKey];
    
    NSData *derivedReceiverMaterial = [HKDFKit deriveKey:masterReceiverKey.keyData info:info salt:salt outputSize:64];
    RootKey *receiveRootKey = [[RootKey alloc] initWithData:[derivedReceiverMaterial subdataWithRange:NSMakeRange(0, 32)]];
    ChainKey *receiveChainKey = [[ChainKey alloc] initWithData:[derivedReceiverMaterial subdataWithRange:NSMakeRange(32, 32)] index:0];
    _receiverRootChain = [[RootChain alloc] initWithRootKey:receiveRootKey chainKey:receiveChainKey];
}

- (PreKeyExchange *)preKeyExchange {
    NSData *signature = [Ed25519 sign:self.baseKeyPublic withKeyPair:self.senderIdentityKey.keyPair];
    PreKeyExchange *preKeyExchange = [[PreKeyExchange alloc] initWithSenderId:self.senderId
                                                                   receiverId:self.receiverId
                                                         signedTargetPreKeyId:self.preKey.signedPreKeyId
                                                            sentSignedBaseKey:self.baseKeyPublic
                                                      senderIdentityPublicKey:self.senderIdentityKey.publicKey
                                                    receiverIdentityPublicKey:self.receiverIdentityPublicKey
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
    RootChain *senderRootChain = self.senderRootChain;
    ChainKey  *senderChainKey  = senderRootChain.chainKey;
    MessageKey *messageKey     = senderChainKey.messageKey;
    
    NSData *senderRatchetKey   = senderRootChain.ourRatchetKeyPair.publicKey;
    NSData *encryptedText = [AES_CBC encryptCBCMode:message withKey:messageKey.cipherKey withIV:messageKey.iv];
    
    NSLog(@"ENCRYPTING WITH MESSAGE KEY: %@", messageKey.cipherKey);
    
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
    SessionState *sessionState = self.previousSessionStates[encryptedMessage.senderRatchetKey][messageIndex];

    if(![HMAC verifyWithMac:[encryptedMessage mac]
          senderIdentityKey:self.receiverIdentityPublicKey
        receiverIdentityKey:self.senderIdentityKey.publicKey
                     macKey:sessionState.messageKey.macKey
             serializedData:encryptedMessage.serializedData]) {
        NSLog(@"FAILED HMAC VERIFICATION");
    }
    
    NSLog(@"DECRYPTING WITH MESSAGE KEY: %@", sessionState.messageKey.cipherKey);
    
    NSData *decryptedData = [AES_CBC decryptCBCMode:encryptedMessage.cipherText
                                            withKey:sessionState.messageKey.cipherKey
                                             withIV:sessionState.messageKey.iv];
    return decryptedData;
}

- (void)processReceiverChain:(EncryptedMessage *)encryptedMessage {
    NSData *senderRatchetKey = encryptedMessage.senderRatchetKey;
    if(!self.previousSessionStates[senderRatchetKey]) {
        if(encryptedMessage.previousIndex > self.receiverRootChain.chainKey.index) {
            [self sessionStatesForDesiredIndex:encryptedMessage.previousIndex
                              senderRatchetKey:self.receiverRootChain.theirRatchetKey];
        }
    }
    [self ratchetRootChains:encryptedMessage.senderRatchetKey];
    [self sessionStatesForDesiredIndex:encryptedMessage.index
                      senderRatchetKey:self.receiverRootChain.theirRatchetKey];
}

- (void)sessionStatesForDesiredIndex:(int)index senderRatchetKey:(NSData *)senderRatchetKey {
    while(index >= self.receiverRootChain.chainKey.index) {
        SessionState *sessionState = [[SessionState alloc] initWithMessageKey:self.receiverRootChain.chainKey.messageKey
                                                             senderRatchetKey:senderRatchetKey
                                                                        index:self.receiverRootChain.chainKey.index];
        
        NSString *stateIndex = [NSString stringWithFormat:@"%d", self.receiverRootChain.chainKey.index];
        NSMutableDictionary *previousStates = [[NSMutableDictionary alloc] initWithDictionary:self.previousSessionStates];
        NSMutableDictionary *ratchetStates = [[NSMutableDictionary alloc] initWithDictionary:[previousStates objectForKey:senderRatchetKey]];
        [ratchetStates setObject:sessionState forKey:stateIndex];
        [previousStates setObject:ratchetStates forKey:senderRatchetKey];
        self.previousSessionStates = [previousStates copy];
        [self setReceiverRootChain:[self.receiverRootChain iterateChainKey]];
    }
}

- (void)ratchetRootChains:(NSData *)theirEphemeral {
    if(![self alreadyReceivedEphemeral:theirEphemeral]) {
        [self ratchetReceiverRootChain:theirEphemeral];
        [self ratchetSenderRootChain];
        
    }
}

- (void)ratchetReceiverRootChain:(NSData *)theirEphemeral {
    ECKeyPair *ourEphemeral = self.receiverRootChain.ourRatchetKeyPair;
    self.receiverRootChain = [[RootChain alloc] iterateRootKeyWithTheirEphemeral:theirEphemeral
                                                                        ourEphemeral:ourEphemeral];
}

- (void)ratchetSenderRootChain {
    NSData *theirEphemeral = self.receiverRootChain.theirRatchetKey;
    ECKeyPair *ourEphemeral = [Curve25519 generateKeyPair];
    self.senderRootChain = [[RootChain alloc] iterateRootKeyWithTheirEphemeral:theirEphemeral
                                                                      ourEphemeral:ourEphemeral];
    self.receiverRootChain.ourRatchetKeyPair = ourEphemeral;
    
    NSMutableDictionary *previousStates = [[NSMutableDictionary alloc] initWithDictionary:self.previousSessionStates];
    NSMutableArray *previousRatchets = [[NSMutableArray alloc] initWithArray:previousStates[kReceivedSenderRatchets]];
    [previousRatchets addObject:theirEphemeral];
    [previousStates setObject:previousRatchets forKey:kReceivedSenderRatchets];
    self.previousSessionStates = previousStates;
}

- (BOOL)alreadyReceivedEphemeral:(NSData *)theirEphemeral {
    return([self.previousSessionStates[kReceivedSenderRatchets] containsObject:theirEphemeral]);
}

- (void)cleanupSessionState:(SessionState *)sessionState {
    //[self.previousSessionStates[sessionState.senderRatchetKey] removeObject:sessionState];
}

@end
