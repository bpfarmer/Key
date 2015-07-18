//
//  AttachmentKey.m
//  Key
//
//  Created by Brendan Farmer on 7/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "AttachmentKey.h"
#import <25519/Ed25519.h>
#import <25519/Curve25519.h>
#import <25519/Randomness.h>
#import "KeyDerivation.h"

@implementation AttachmentKey

- (instancetype)init {
    self = [super init];
    if(self) {
        NSData *randomBytes = [Randomness generateRandomBytes:64];
        KeyDerivation *keyDerivation = [[KeyDerivation alloc] fromData:randomBytes];
        _cipherKey = keyDerivation.cipherKey;
        _iv        = keyDerivation.iv;
        _macKey    = keyDerivation.macKey;
    }
    return self;
}

@end
