//
//  RootChain.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/6/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KDatabaseObject.h"

@class MessageKey;
@class ECKeyPair;
@class SessionState;

@interface RootChain : KDatabaseObject

@property (nonatomic) NSData    *rootKey;
@property (nonatomic) NSNumber  *index;
@property (nonatomic) NSData    *chainKey;
@property (nonatomic) ECKeyPair *ourRatchetKeyPair;
@property (nonatomic) NSData    *theirRatchetKey;

- (instancetype)initWithRootKey:(NSData *)rootKey chainKey:(NSData *)chainKey;

- (MessageKey *)messageKey;
- (void)iterateChainKey;
- (void)iterateRootKeyWithTheirEphemeral:(NSData *)theirEphemeral ourEphemeral:(ECKeyPair *)ourEphemeral;

@end
