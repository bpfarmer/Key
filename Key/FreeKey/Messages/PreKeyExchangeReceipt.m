//
//  PreKeyExchangeReceipt.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/7/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "PreKeyExchangeReceipt.h"
#import "PreKey.h"
#import "IdentityKey.h"

@implementation PreKeyExchangeReceipt

- (instancetype)initFromSenderId:(NSString *)senderId
                      receiverId:(NSString *)receiverId
                 receivedBaseKey:(NSData *)receivedBaseKey
         senderIdentityPublicKey:(NSData *)senderIdentityPublicKey
       receiverIdentityPublicKey:(NSData *)receiverIdentityPublicKey {
    
    self = [super init];
    
    if(self) {
        _senderId           = senderId;
        _receiverId         = receiverId;
        _receivedBaseKey    = receivedBaseKey;
        _senderIdentityPublicKey  = senderIdentityPublicKey;
        _receiverIdentityPublicKey = receiverIdentityPublicKey;
    }
    
    return self;
}

- (void)sendToServer {
    
}

@end
