//
//  PreKeyExchange.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/3/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "PreKeyExchange.h"
#import "PreKeyExchangeReceipt.h"
#import "PreKey.h"
#import "PreKeyExchange+Serialize.h"

@implementation PreKeyExchange

- (instancetype)initWithSenderId:(NSString *)senderId
                      receiverId:(NSString *)receiverId
            signedTargetPreKeyId:(NSString *)signedTargetPreKeyId
               sentSignedBaseKey:(NSData *)sentSignedBaseKey
         senderIdentityPublicKey:(NSData *)senderIdentityPublicKey
       receiverIdentityPublicKey:(NSData *)receiverIdentityPublicKey
                baseKeySignature:(NSData *)baseKeySignature{
    
    self = [super init];
    
    if(self) {
        _senderId = senderId;
        _receiverId = receiverId;
        _signedTargetPreKeyId = signedTargetPreKeyId;
        _senderIdentityPublicKey = senderIdentityPublicKey;
        _sentSignedBaseKey = sentSignedBaseKey;
        _receiverIdentityPublicKey = receiverIdentityPublicKey;
    }
    
    return self;
}

- (PreKeyExchangeReceipt *)createPreKeyExchangeReceipt {
    PreKeyExchangeReceipt *receipt = [[PreKeyExchangeReceipt alloc] initFromSenderId:self.senderId
                                                                          receiverId:self.receiverId
                                                                     receivedBaseKey:self.sentSignedBaseKey
                                                             senderIdentityPublicKey:self.senderIdentityPublicKey
                                                           receiverIdentityPublicKey:self.receiverIdentityPublicKey];
    return receipt;
}

+ (NSArray *)remoteKeys {
    return @[@"senderId", @"receiverId", @"signedTargetPreKeyId", @"sentSignedBaseKey",
             @"senderIdentityPublicKey", @"receiverIdentityPublicKey", @"baseKeySignature"];
}

@end
