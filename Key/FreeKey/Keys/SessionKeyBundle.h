//
//  SessionKeyBundle.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECKeyPair;
@class BaseKey;
@class PreKey;

@interface SessionKeyBundle : NSObject

@property (nonatomic, readonly) NSData *receiverBasePublicKey;
@property (nonatomic, readonly) NSData *receiverPublicKey;
@property (nonatomic, readonly) ECKeyPair *senderIdentityKey;
@property (nonatomic, readonly) ECKeyPair *senderBaseKey;
@property (nonatomic) BOOL isAlice;

- (instancetype)initWithSenderIdentityKey:(ECKeyPair *)senderIdentityKey senderBaseKey:(ECKeyPair *)senderBaseKey receiverBasePublicKey:(NSData *)receiverBasePublicKey receiverPublicKey:(NSData *)receiverPublicKey isAlice:(BOOL)isAlice;

- (instancetype)oppositeBundle;
- (void)setRolesWithFirstKey:(NSData *)firstKey secondKey:(NSData *)secondKey;

@end
