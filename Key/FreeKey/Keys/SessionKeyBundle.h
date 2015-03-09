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

@property (nonatomic, readonly) NSData *theirBaseKey;
@property (nonatomic, readonly) NSData *theirIdentityKey;
@property (nonatomic, readonly) ECKeyPair *ourIdentityKeyPair;
@property (nonatomic, readonly) ECKeyPair *ourBaseKey;
@property (nonatomic) BOOL isAlice;

- (instancetype)initWithTheirBaseKey:(NSData *)theirBaseKey
                    theirIdentityKey:(NSData *)theirIdentityKey
                  ourIdentityKeyPair:(ECKeyPair *)ourIdentityKeyPair
                          ourBaseKey:(ECKeyPair *)ourBaseKey;

- (instancetype)oppositeBundle;
- (void)setRolesWithFirstKey:(NSData *)firstKey secondKey:(NSData *)secondKey;

@end
