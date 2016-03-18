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
#import "FreeKey.h"

@implementation PreKeyExchange

- (instancetype)initWithSenderId:(NSString *)senderId
                 senderPublicKey:(NSData *)senderPublicKey
                   basePublicKey:(NSData *)basePublicKey
                      receiverId:(NSString *)receiverId
                        preKeyId:(NSString *)preKeyId {
    
    self = [super init];
    
    if(self) {
        _senderId                   = senderId;
        _senderPublicKey            = senderPublicKey;
        _basePublicKey              = basePublicKey;
        _receiverId                 = receiverId;
        _preKeyId                   = preKeyId;
    }
    
    return self;
    
}

- (PreKeyExchangeReceipt *)createPreKeyExchangeReceipt {
    PreKeyExchangeReceipt *receipt = [[PreKeyExchangeReceipt alloc] initFromSenderId:self.senderId receiverId:self.receiverId receivedBasePublicKey:self.basePublicKey];
    return receipt;
}

+ (NSArray *)remoteKeys {
    return @[@"senderId", @"senderPublicKey", @"basePublicKey", @"receiverId", @"preKeyId"];
}

+ (NSString *)remoteAlias {
    return kPreKeyExchangeRemoteAlias;
}

- (NSString *)remoteUserId {
    return [self.senderId componentsSeparatedByString:@"_"].firstObject;
}

- (NSString *)remoteDeviceId {
    return self.senderId;
}

@end
