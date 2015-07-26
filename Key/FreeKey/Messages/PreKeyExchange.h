//
//  PreKeyExchange.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/3/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeyExchange.h"

@class PreKey;
@class IdentityKey;
@class PreKeyExchangeReceipt;

@interface PreKeyExchange : KeyExchange

@property (nonatomic, readonly) NSString *senderId;
@property (nonatomic, readonly) NSData   *senderPublicKey;
@property (nonatomic, readonly) NSData   *basePublicKey;
@property (nonatomic, readonly) NSString *receiverId;
@property (nonatomic, readonly) NSData   *receiverPublicKey;
@property (nonatomic, readonly) NSString *preKeyId;
@property (nonatomic, readonly) NSData   *signature;

- (instancetype)initWithSenderId:(NSString *)senderId
                 senderPublicKey:(NSData *)senderPublicKey
                   basePublicKey:(NSData *)basePublicKey
                      receiverId:(NSString *)receiverId
               receiverPublicKey:(NSData *)receiverPublicKey
                        preKeyId:(NSString *)preKeyId
                       signature:(NSData *)signature;

- (PreKeyExchangeReceipt *)createPreKeyExchangeReceipt;

- (NSString *)remoteUserId;
- (NSString *)remoteDeviceId;

@end