//
//  PreKeyExchange.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/3/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PreKey;
@class IdentityKey;
@class PreKeyExchangeReceipt;

@interface PreKeyExchange : NSObject <NSSecureCoding>

@property (nonatomic, readonly) NSString *senderId;
@property (nonatomic, readonly) NSString *receiverId;
@property (nonatomic, readonly) NSString *targetPreKeyId;
@property (nonatomic, readonly) NSString *signedTargetPreKeyId;
@property (nonatomic, readonly) NSData   *sentBaseKey;
@property (nonatomic, readonly) NSData   *sentSignedBaseKey;
@property (nonatomic, readonly) NSData *senderIdentityPublicKey;
@property (nonatomic, readonly) NSData *receiverIdentityPublicKey;

- (instancetype)initWithSenderId:(NSString *)senderId
                      receiverId:(NSString *)receiverId
                  targetPreKeyId:(NSString *)targetPreKeyId
            signedTargetPreKeyId:(NSString *)signedTargetPreKeyId
                     sentBaseKey:(NSData *)sentBaseKey
               sentSignedBaseKey:(NSData *)sentSignedBaseKey
         senderIdentityPublicKey:(NSData *)senderIdentityPublicKey
       receiverIdentityPublicKey:(NSData *)receiverIdentityPublicKey;

- (PreKeyExchangeReceipt *)createPreKeyExchangeReceipt;
- (void)sendToServer;

@end