//
//  RootChain.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/6/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "RootChain.h"
#import "RootKey.h"
#import "ChainKey.h"
#import "KeyDerivation.h"
#import <25519/Curve25519.h>
#import <25519/Ed25519.h>

@implementation RootChain

- (instancetype)initWithRootKey:(RootKey *)rootKey chainKey:(ChainKey *)chainKey {
    self = [super init];
    if(self) {
        _rootKey  = rootKey;
        _chainKey = chainKey;
    }
    return self;
}

- (instancetype)initWithRootKey:(RootKey *)rootKey
                       chainKey:(ChainKey *)chainKey
                 ratchetKeyPair:(ECKeyPair *)ratchetKeyPair
                     ratchetKey:(NSData *)ratchetKey {
    self = [super init];
    if(self) {
        _rootKey = rootKey;
        _chainKey = chainKey;
        _ratchetKeyPair = ratchetKeyPair;
        _ratchetKey = ratchetKey;
    }
    return self;
}

- (instancetype)iterateRootKeyWithTheirEphemeral:(NSData *)theirEphemeral ourEphemeral:(ECKeyPair *)ourEphemeral {
    NSData *sharedSecret = [Curve25519 generateSharedSecretFromPublicKey:theirEphemeral andKeyPair:ourEphemeral];
    
    KeyDerivation *keyMaterial = [[KeyDerivation alloc] fromSharedSecret:sharedSecret rootKey:self.rootKey.keyData];
    
    RootChain *nextRootChain = [[RootChain alloc] initWithRootKey:[[RootKey alloc] initWithData:keyMaterial.cipherKey]
                                                         chainKey:[[ChainKey alloc] initWithData:keyMaterial.macKey
                                                                                           index:0]];
    [nextRootChain setRatchetKey:theirEphemeral];
    [nextRootChain setRatchetKeyPair:ourEphemeral];
    return nextRootChain;
}

- (instancetype)iterateChainKey {
    RootChain *nextRootChain = [[RootChain alloc] initWithRootKey:self.rootKey chainKey:[self.chainKey nextChainKey]];
    [nextRootChain setRatchetKeyPair:self.ratchetKeyPair];
    [nextRootChain setRatchetKey:self.ratchetKey];
    return nextRootChain;
}

@end
