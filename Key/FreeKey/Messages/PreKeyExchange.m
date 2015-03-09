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

@implementation PreKeyExchange

- (instancetype)initWithSenderId:(NSString *)senderId
                      receiverId:(NSString *)receiverId
                  targetPreKeyId:(NSString *)targetPreKeyId
            signedTargetPreKeyId:(NSString *)signedTargetPreKeyId
                     sentBaseKey:(NSData *)sentBaseKey
               sentSignedBaseKey:(NSData *)sentSignedBaseKey
         senderIdentityPublicKey:(NSData *)senderIdentityPublicKey
       receiverIdentityPublicKey:(NSData *)receiverIdentityPublicKey {
    
    self = [super init];
    
    if(self) {
        _senderId = senderId;
        _receiverId = receiverId;
        _targetPreKeyId = targetPreKeyId;
        _signedTargetPreKeyId = signedTargetPreKeyId;
        _sentBaseKey = sentBaseKey;
        _senderIdentityPublicKey = senderIdentityPublicKey;
        _receiverIdentityPublicKey = receiverIdentityPublicKey;
    }
    
    return self;
}

- (PreKeyExchangeReceipt *)createPreKeyExchangeReceipt {
    PreKeyExchangeReceipt *receipt = [[PreKeyExchangeReceipt alloc] initFromSenderId:self.senderId
                                                                          receiverId:self.receiverId
                                                                     receivedBaseKey:self.sentBaseKey
                                                             senderIdentityPublicKey:self.senderIdentityPublicKey
                                                           receiverIdentityPublicKey:self.receiverIdentityPublicKey];
    return receipt;
}

- (void)sendToServer {
    
}

@end
