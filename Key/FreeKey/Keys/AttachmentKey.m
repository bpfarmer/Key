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
#import "AES_CBC.h"

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

- (NSData *)encryptObject:(KDatabaseObject *)object {
    NSData *serializedObject = [NSKeyedArchiver archivedDataWithRootObject:object];
    return [AES_CBC encryptCBCMode:serializedObject withKey:self.cipherKey withIV:self.iv];
}

- (KDatabaseObject *)decryptCipherText:(NSData *)cipherText {
    NSData *plainText = [AES_CBC decryptCBCMode:cipherText withKey:self.cipherKey withIV:self.iv];
    return [NSKeyedUnarchiver unarchiveObjectWithData:plainText];
}

@end
