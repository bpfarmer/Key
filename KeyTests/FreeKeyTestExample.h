//
//  FreeKeyTestExample.h
//  Key
//
//  Created by Brendan Farmer on 3/20/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KUser;
@class IdentityKey;
@class ECKeyPair;
@class PreKey;
@class PreKeyExchange;
@class Session;

@interface FreeKeyTestExample : NSObject

@property KUser *alice;
@property KUser *bob;
@property IdentityKey *aliceIdentityKey;
@property IdentityKey *bobIdentityKey;
@property ECKeyPair *aliceBaseKeyPair;
@property ECKeyPair *bobBaseKeyPair;
@property PreKey *bobPreKey;
@property PreKeyExchange *alicePreKeyExchange;

- (Session *)aliceSession;
- (Session *)bobSession;

@end
