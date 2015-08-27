//
//  SessionKeyBundle.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "SessionKeyBundle.h"
#import "PreKey.h"
#import <25519/Ed25519.h>
#import <25519/Curve25519.h>

@implementation SessionKeyBundle

- (instancetype)initWithSenderIdentityKey:(ECKeyPair *)senderIdentityKey senderBaseKey:(ECKeyPair *)senderBaseKey receiverBasePublicKey:(NSData *)receiverBasePublicKey receiverPublicKey:(NSData *)receiverPublicKey isAlice:(BOOL)isAlice {
    self = [super init];
    
    if(self) {
        _receiverBasePublicKey = receiverBasePublicKey;
        _receiverPublicKey     = receiverPublicKey;
        _senderIdentityKey     = senderIdentityKey;
        _senderBaseKey         = senderBaseKey;
        _isAlice               = isAlice;
    }

    return self;
}

- (void)setRolesWithFirstKey:(NSData *)firstKey secondKey:(NSData *)secondKey {
    const char *ourBuffer[32];
    const char *theirBuffer[32];
    [firstKey getBytes:&ourBuffer length:32];
    [secondKey getBytes:&theirBuffer length:32];
    
    // Compare base public keys to determine roles
    if(strcmp(ourBuffer, theirBuffer) > 0) {
        _isAlice = YES;
    }else {
        _isAlice = NO;
    }
}

- (instancetype)oppositeBundle {
    if(self) {
        _isAlice = !self.isAlice;
    }
    return self;
}

@end
