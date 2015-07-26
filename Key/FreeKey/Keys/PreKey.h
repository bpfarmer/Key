//
//  PreKey.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/3/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeyExchange.h"

@class ECKeyPair;

@interface PreKey : KeyExchange

// TODO: if we're going to provide ID keys, probably need to sign them

@property (nonatomic, readonly) NSString *userId;
@property (nonatomic, readonly) NSData   *basePublicKey;
@property (nonatomic, readonly) NSData   *signature;
@property (nonatomic, readonly) NSData   *publicKey;
@property (nonatomic, readonly) ECKeyPair *baseKeyPair;

- (instancetype)initWithUniqueId:(NSString *)uniqueId userId:(NSString *)userId basePublicKey:(NSData*)basePublicKey signature:(NSData*)signature publicKey:(NSData*)publicKey baseKeyPair:(ECKeyPair *)baseKeyPair;

@end