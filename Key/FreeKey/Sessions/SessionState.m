//
//  SessionState.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/7/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "SessionState.h"
#import "MessageKey.h"

@implementation SessionState

- (instancetype)initWithMessageKey:(MessageKey *)messageKey senderRatchetKey:(NSData *)senderRatchetKey messageIndex:(NSNumber *)messageIndex sessionId:(NSString *)sessionId{
    self = [super init];
    
    if(self) {
        _cipherKey        = messageKey.cipherKey;
        _iv               = messageKey.iv;
        _macKey           = messageKey.macKey;
        _senderRatchetKey = senderRatchetKey;
        _messageIndex     = messageIndex;
        _sessionId        = sessionId;
    }
    
    return self;
}

- (MessageKey *)messageKey {
    return [[MessageKey alloc] initWithCipherKey:self.cipherKey macKey:self.macKey iv:self.iv index:self.messageIndex];
}

@end
