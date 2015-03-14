//
//  PreKeyExchangeReceipt.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/7/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IdentityKey;

@interface PreKeyExchangeReceipt : NSObject <NSSecureCoding>

@property (nonatomic, readonly) NSString *senderId;
@property (nonatomic, readonly) NSString *receiverId;
@property (nonatomic, readonly) NSData   *receivedBaseKey;
@property (nonatomic, readonly) NSData   *senderIdentityPublicKey;
@property (nonatomic, readonly) NSData   *receiverIdentityPublicKey;

- (instancetype)initFromSenderId:(NSString *)senderId
                      receiverId:(NSString *)receiverId
                 receivedBaseKey:(NSData *)receivedBaseKey
         senderIdentityPublicKey:(NSData *)senderIdentityPublicKey
       receiverIdentityPublicKey:(NSData *)receiverIdentityPublicKey;

- (void)sendToServer;

@end
