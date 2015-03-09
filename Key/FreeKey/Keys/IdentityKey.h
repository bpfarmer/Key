//
//  IdentityKey.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KYapDatabaseObject.h"

@class ECKeyPair;

@interface IdentityKey : KYapDatabaseObject

@property (nonatomic, readonly) NSString *userId;
@property (nonatomic, readonly) NSData *publicKey;
@property (nonatomic, readonly) ECKeyPair *keyPair;

- (instancetype)initWithPublicKey:(NSData *)publicKey userId:(NSString *)userId;
- (instancetype)initWithKeyPair:(ECKeyPair *)keyPair userId:(NSString *)userId;
- (BOOL)isTrustedIdentityKey;

+ (instancetype)activeIdentityKeyForUserId:(NSString *)userId;

@end
