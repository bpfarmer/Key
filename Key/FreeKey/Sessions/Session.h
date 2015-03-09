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

@interface Session : KYapDatabaseObject

@property (nonatomic, readonly) NSString *senderId;
@property (nonatomic, readonly) NSString *receiverId;
@property (nonatomic, readonly) PreKey *preKey;
@property (nonatomic, readonly) NSData *baseKeyPublic;
@property (nonatomic, readonly) IdentityKey *senderIdentityKey;
@property (nonatomic, readonly) NSData *receiverIdentityPublicKey;
@property (nonatomic, retain) RootChain *senderRootChain;
@property (nonatomic, retain) RootChain *receiverRootChain;
@property (nonatomic) int previousIndex;
@property (nonatomic, retain) NSMutableDictionary *previousSessionStates;

- (instancetype)initWithReceiverId:(NSString *)receiverId identityKey:(IdentityKey *)identityKey;
- (void)addOurPreKey:(PreKey *)ourPreKey preKeyExchange:(PreKeyExchange *)preKeyExchange;
- (void)addPreKey:(PreKey *)preKey;

- (PreKeyExchange *)preKeyExchange;
- (EncryptedMessage *)encryptMessage:(NSData *)message;
- (NSData *)decryptMessage:(EncryptedMessage *)encryptedMessage;

@end
