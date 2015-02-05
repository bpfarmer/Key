//
//  KMessageCrypt.m
//  Key
//
//  Created by Brendan Farmer on 1/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KMessageCrypt.h"
#import "KMessage.h"
#import "KUser.h"

@implementation KMessageCrypt

- (instancetype)initWithMessage:(KMessage *)message keyPair:(KKeyPair *)keyPair {
    self = [super initWithUniqueId:nil];
    
    if (self) {
        _recipientId = [keyPair userId];
        _keyPairId   = [keyPair uniqueId];
        _bodyCrypt = [keyPair encryptText:[message body]];
    }
    
    return self;
}

@end
