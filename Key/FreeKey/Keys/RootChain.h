//
//  RootChain.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/6/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RootKey;
@class ChainKey;
@class ECKeyPair;
@class SessionState;

@interface RootChain : NSObject

@property (nonatomic, strong) RootKey  *rootKey;
@property (nonatomic, strong) ChainKey *chainKey;
@property (nonatomic, strong) ECKeyPair *ratchetKeyPair;
@property (nonatomic, strong) NSData *ratchetKey;

- (instancetype)initWithRootKey:(RootKey *)rootKey chainKey:(ChainKey *)chainKey;
- (instancetype)initWithRootKey:(RootKey *)rootKey
                       chainKey:(ChainKey *)chainKey
                 ratchetKeyPair:(ECKeyPair *)ratchetKeyPair
                     ratchetKey:(NSData *)ratchetKey;
- (instancetype)iterateChainKey;
- (instancetype)iterateRootKeyWithTheirEphemeral:(NSData *)theirEphemeral ourEphemeral:(ECKeyPair *)ourEphemeral;

- (void)setRatchetKeyPair:(ECKeyPair *)ratchetKeyPair;

@end
