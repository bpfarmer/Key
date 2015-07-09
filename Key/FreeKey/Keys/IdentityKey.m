//
//  IdentityKey.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "IdentityKey.h"
#import <25519/Curve25519.h>
#import <25519/Ed25519.h>
#import "IdentityKey+Serialize.h"

@implementation IdentityKey

- (instancetype)init {
    self = [super init];
    
    if(self) {
        _active = YES;
    }
    
    return self;
}
- (instancetype)initWithPublicKey:(NSData *)publicKey userId:(NSString *)userId {
    self = [self init];
    
    if(self) {
        _publicKey = publicKey;
        _userId    = userId;
    }
    return self;
}

- (instancetype)initWithKeyPair:(ECKeyPair *)keyPair userId:(NSString *)userId{
    self = [self init];
    
    if(self) {
        _publicKey = keyPair.publicKey;
        _keyPair   = keyPair;
        _userId    = userId;
    }
    return self;
}

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                          userId:(NSString *)userId
                       publicKey:(NSData *)publicKey
                         keyPair:(ECKeyPair *)keyPair
                          active:(BOOL)active{
    self = [self initWithUniqueId:uniqueId];
    
    if(self) {
        _userId    = userId;
        _publicKey = publicKey;
        _keyPair   = keyPair;
        _active    = active;
    }
    
    return self;
}

- (BOOL)isTrustedIdentityKey {
    return YES;
}

+ (instancetype)activeIdentityKeyForUserId:(NSString *)userId {
    IdentityKey *activeKey = [[IdentityKey alloc] initWithKeyPair:[Curve25519 generateKeyPair] userId:userId];
    return activeKey;
}

@end
