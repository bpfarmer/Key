//
//  EncryptedMessage.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "EncryptedMessage.h"
#import <CommonCrypto/CommonCrypto.h>
#import "HMAC.h"
#import "FreeKey.h"

@implementation EncryptedMessage

- (instancetype)initWithSenderId:(NSString *)senderId receiverId:(NSString *)receiverId serializedData:(NSData *)serializedData senderRatchetKey:(NSData *)senderRatchetKey index:(NSNumber *)index previousIndex:(NSNumber *)previousIndex {
    self = [super init];
    
    if(self) {
        _senderRatchetKey = senderRatchetKey;
        _senderId         = senderId;
        _receiverId       = receiverId;
        _serializedData   = serializedData;
        _index            = index;
        _previousIndex    = previousIndex;
    }
    return self;
}

+ (NSArray *)remoteKeys {
    return @[@"senderRatchetKey", @"receiverId", @"senderId", @"serializedData", @"index", @"previousIndex"];
}

+ (NSString *)remoteAlias {
    return kEncryptedMessageRemoteAlias;
}

- (void)addMetadataFromLocalUserId:(NSString *)localUserId toRemoteUserId:(NSString *)remoteUserId {
    self.senderId   = localUserId;
    self.receiverId = remoteUserId;
}

@end
