//
//  SessionState.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/7/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "SessionState.h"

@class MessageKey;

@implementation SessionState

- (instancetype)initWithMessageKey:(MessageKey *)messageKey index:(int)index {
    self = [super init];
    
    if(self) {
        _messageKey = messageKey;
        _index      = index;
    }
    
    return self;
}

@end
