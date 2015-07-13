//
//  RootChain.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/6/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KDatabaseObject.h"

@class RootKey;
@class ChainKey;
@class ECKeyPair;
@class SessionState;

@interface RootChain : KDatabaseObject

@property (nonatomic) RootKey   *rootKey;
@property (nonatomic) ChainKey  *chainKey;
@property (nonatomic) ECKeyPair *ourRatchetKeyPair;
@property (nonatomic) NSData    *theirRatchetKey;

- (instancetype)initWithRootKey:(RootKey *)rootKey chainKey:(ChainKey *)chainKey;
- (instancetype)initWithRootKey:(RootKey *)rootKey
                       chainKey:(ChainKey *)chainKey
              ourRatchetKeyPair:(ECKeyPair *)ourRatchetKeyPair
                theirRatchetKey:(NSData *)theirRatchetKey;
- (instancetype)iterateChainKey;
- (instancetype)iterateRootKeyWithTheirEphemeral:(NSData *)theirEphemeral ourEphemeral:(ECKeyPair *)ourEphemeral;

//- (void)setRatchetKeyPair:(ECKeyPair *)ratchetKeyPair;

@end
