//
//  SessionState.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/7/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "SessionState.h"
#import "ChainKey.h"
#import "SessionState+Serialize.h"

@implementation SessionState

- (instancetype)initWithMessageKey:(MessageKey *)messageKey senderRatchetKey:(NSData *)senderRatchetKey messageIndex:(int)messageIndex sessionId:(NSString *)sessionId{
    self = [super init];
    
    if(self) {
        _messageKey       = messageKey;
        _senderRatchetKey = senderRatchetKey;
        _messageIndex     = messageIndex;
        _sessionId        = sessionId;
    }
    
    return self;
}

@end
