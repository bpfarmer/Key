//
//  RootChain.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/6/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KeyDerivation.h"
#import <25519/Curve25519.h>
#import <25519/Ed25519.h>
#import "RootChain+Serialize.h"
#import "MessageKey.h"
#import <CommonCrypto/CommonCrypto.h>

#define kTSKeySeedLength 1

static uint8_t kMessageKeySeed[kTSKeySeedLength]    = {01};
static uint8_t kChainKeySeed[kTSKeySeedLength]      = {02};

@implementation RootChain

- (instancetype)initWithRootKey:(NSData *)rootKey chainKey:(NSData *)chainKey {
    self = [super init];
    if(self) {
        _rootKey  = rootKey;
        _chainKey = chainKey;
        _index    = [[NSNumber alloc] initWithInt:0];
    }
    
    return self;
}

- (MessageKey *)messageKey {
    KeyDerivation *keyMaterial = [[KeyDerivation alloc] fromData:[self baseMaterial:[NSData dataWithBytes:kMessageKeySeed length:kTSKeySeedLength] forKey:self.chainKey]];
    MessageKey *messageKey = [[MessageKey alloc] initWithCipherKey:keyMaterial.cipherKey
                                                 macKey:keyMaterial.macKey
                                                     iv:keyMaterial.iv
                                                  index:self.index];
    return messageKey;
}

- (void)iterateRootKeyWithTheirEphemeral:(NSData *)theirEphemeral ourEphemeral:(ECKeyPair *)ourEphemeral {
    NSData *sharedSecret = [Curve25519 generateSharedSecretFromPublicKey:theirEphemeral andKeyPair:ourEphemeral];
    KeyDerivation *keyMaterial = [[KeyDerivation alloc] fromSharedSecret:sharedSecret rootKey:self.rootKey];
    self.rootKey  = keyMaterial.cipherKey;
    self.chainKey = keyMaterial.macKey;
    self.ourRatchetKeyPair = ourEphemeral;
    [self save];
}

- (void)iterateChainKey {
    self.chainKey = [self baseMaterial:[NSData dataWithBytes:kChainKeySeed length:kTSKeySeedLength] forKey:self.chainKey];
    [self incrementIndex];
    [self save];
}

- (void)incrementIndex {
    self.index    = [[NSNumber alloc] initWithInt:self.index.intValue + 1];
}

- (NSData*)baseMaterial:(NSData*)seed forKey:(NSData *)key{
    uint8_t result[CC_SHA256_DIGEST_LENGTH] = {0};
    CCHmacContext ctx;
    CCHmacInit(&ctx, kCCHmacAlgSHA256, [key bytes], [key length]);
    CCHmacUpdate(&ctx, [seed bytes], [seed length]);
    CCHmacFinal(&ctx, result);
    return [NSData dataWithBytes:result length:sizeof(result)];
}


@end
