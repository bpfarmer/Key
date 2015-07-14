//
//  PreKeyExchange.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/3/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSendable.h"
#import "KDatabaseObject.h"

@class PreKey;
@class IdentityKey;
@class PreKeyExchangeReceipt;

@interface PreKeyExchange : KDatabaseObject <KSendable>

@property (nonatomic, readwrite) NSString *senderId;
@property (nonatomic, readonly) NSString *senderDeviceId;
@property (nonatomic, readonly) NSString *receiverId;
@property (nonatomic, readonly) NSString *receiverDeviceId;
@property (nonatomic, readonly) NSString *signedTargetPreKeyId;
@property (nonatomic, readonly) NSData *sentSignedBaseKey;
@property (nonatomic, readonly) NSData *senderIdentityPublicKey;
@property (nonatomic, readonly) NSData *receiverIdentityPublicKey;
@property (nonatomic, readonly) NSData *baseKeySignature;
@property (nonatomic, readwrite) NSString *remoteStatus;

- (instancetype)initWithSenderId:(NSString *)senderId
                      receiverId:(NSString *)receiverId
            signedTargetPreKeyId:(NSString *)signedTargetPreKeyId
               sentSignedBaseKey:(NSData *)sentSignedBaseKey
         senderIdentityPublicKey:(NSData *)senderIdentityPublicKey
       receiverIdentityPublicKey:(NSData *)receiverIdentityPublicKey
                baseKeySignature:(NSData *)baseKeySignature;

- (PreKeyExchangeReceipt *)createPreKeyExchangeReceipt;

+ (NSArray *)remoteKeys;

@end