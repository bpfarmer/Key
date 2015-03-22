//
//  RootChain+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 3/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "RootChain+Serialize.h"
#import "RootKey.h"
#import "ChainKey.h"
#import <25519/Curve25519.h>
#import <25519/Ed25519.h>

#define kCoderRootKey @"rootKey"
#define kCoderChainKey @"chainKey"
#define kCoderRatchetKey @"ratchetKey"
#define kCoderRatchetKeyPair @"ratchetKeyPair"

@implementation RootChain(Serialize)

+ (BOOL)supportsSecureCoding{
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    return [self initWithRootKey:[aDecoder decodeObjectOfClass:[RootKey class] forKey:kCoderRootKey]
                        chainKey:[aDecoder decodeObjectOfClass:[ChainKey class] forKey:kCoderChainKey]
                  ourRatchetKeyPair:[aDecoder decodeObjectOfClass:[ECKeyPair class] forKey:kCoderRatchetKeyPair]
                      theirRatchetKey:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderRatchetKey]];
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.rootKey forKey:kCoderRootKey];
    [aCoder encodeObject:self.chainKey forKey:kCoderChainKey];
    [aCoder encodeObject:self.ourRatchetKeyPair forKey:kCoderRatchetKeyPair];
    [aCoder encodeObject:self.theirRatchetKey forKey:kCoderRatchetKey];
}

@end
