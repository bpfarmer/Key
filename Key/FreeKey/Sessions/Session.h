//
//  Session.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KYapDatabaseObject.h"

@class PreKey;
@class RootChain;
@class EncryptedMessage;
@class IdentityKey;
@class PreKeyExchange;
@class PreKeyExchangeReceipt;
@class ECKeyPair;

@interface Session : NSObject

@property (nonatomic, readonly) NSString *senderId;
@property (nonatomic, readonly) NSString *receiverId;
@property (nonatomic, readonly) PreKey *preKey;
@property (nonatomic, readonly) NSData *baseKeyPublic;
@property (nonatomic, readonly) IdentityKey *senderIdentityKey;
@property (nonatomic, readonly) NSData *receiverIdentityPublicKey;
@property (nonatomic, readwrite) RootChain *senderRootChain;
@property (nonatomic, readwrite) RootChain *receiverRootChain;
@property (nonatomic, readwrite) int previousIndex;
@property (nonatomic, readwrite) NSDictionary *previousSessionStates;

- (instancetype)initWithReceiverId:(NSString *)receiverId identityKey:(IdentityKey *)identityKey;
- (instancetype)initWithSenderId:(NSString *)senderId
                      receiverId:(NSString *)receiverId
                          preKey:(PreKey *)preKey
                   baseKeyPublic:(NSData *)baseKeyPublic
               senderIdentityKey:(IdentityKey *)senderIdentityKey
       receiverIdentityPublicKey:(NSData *)receiverIdentityPublicKey
                 senderRootChain:(RootChain *)senderRootChain
               receiverRootChain:(RootChain *)receiverRootChain
                   previousIndex:(int)previousIndex
           previousSessionStates:(NSDictionary *)previousSessionStates;

- (void)addOurPreKey:(PreKey *)ourPreKey preKeyExchange:(PreKeyExchange *)preKeyExchange;
- (PreKeyExchange *)addPreKey:(PreKey *)preKey;

- (PreKeyExchange *)preKeyExchange;
- (EncryptedMessage *)encryptMessage:(NSData *)message;
- (NSData *)decryptMessage:(EncryptedMessage *)encryptedMessage;

@end
