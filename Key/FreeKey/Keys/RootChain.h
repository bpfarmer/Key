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
@property (nonatomic, strong) NSData   *ratchetKey;
@property (nonatomic, strong) ECKeyPair *ratchetKeyPair;

- (instancetype)initWithRootKey:(RootKey*)rootKey chainKey:(ChainKey*)chainKey ratchetKeyPair:(ECKeyPair *)ratchetKeyPair;
- (instancetype)iterateChainKey;
- (instancetype)iterateRootKeyWithTheirEphemeral:(NSData *)theirEphemeral ourEphemeral:(ECKeyPair *)ourEphemeral;
- (BOOL)updateRatchetKey:(NSData *)senderRatchetKey;

@end
