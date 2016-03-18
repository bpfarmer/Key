//
//  PreKeyExchangeReceipt.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/7/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "PreKeyExchangeReceipt.h"

@implementation PreKeyExchangeReceipt

- (instancetype)initFromSenderId:(NSString *)senderId receiverId:(NSString *)receiverId receivedBasePublicKey:(NSData *)receivedBasePublicKey {
    self = [super init];

    if(self) {
        _senderId           = senderId;
        _receiverId         = receiverId;
        _receivedBasePublicKey    = receivedBasePublicKey;
    }
    
    return self;
}

@end
