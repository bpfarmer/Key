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
@class IdentityKey;
@class PreKeyExchange;
@class PreKeyExchangeReceipt;
@class ECKeyPair;

@interface Session : KDatabaseObject

@property (nonatomic, readonly) NSString *senderId;
@property (nonatomic, readonly) NSString *receiverId;
@property (nonatomic, readonly) NSString *deviceId;
@property (nonatomic, readonly) NSString *preKeyId;
@property (nonatomic, readonly) NSData *baseKeyPublic;
@property (nonatomic, readwrite) NSString *senderChainId;
@property (nonatomic, readwrite) NSString *receiverChainId;
@property (nonatomic, readwrite) NSNumber *previousIndex;
@property (nonatomic, readwrite) NSArray  *receivedRatchetKeys;

- (instancetype)initWithSenderId:(NSString *)senderId receiverId:(NSString *)receiverId;

- (void)addOurPreKey:(PreKey *)ourPreKey preKeyExchange:(PreKeyExchange *)preKeyExchange;
- (void)addPreKey:(PreKey *)preKey ourBaseKey:(ECKeyPair *)ourBaseKey;

- (PreKeyExchange *)preKeyExchange;
- (EncryptedMessage *)encryptMessage:(NSData *)message;
- (NSData *)decryptMessage:(EncryptedMessage *)encryptedMessage;

@end
