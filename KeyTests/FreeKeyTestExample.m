//
//  FreeKeyTestExample.m
//  Key
//
//  Created by Brendan Farmer on 3/20/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "FreeKeyTestExample.h"
#import "KUser.h"
#import <25519/Curve25519.h>
#import <25519/Ed25519.h>
#import "PreKeyExchange.h"
#import "PreKey.h"
#import "Session.h"
#import "KStorageManager.h"
#import "KStorageSchema.h"

@implementation FreeKeyTestExample

- (instancetype)init {
    self = [super init];
    return self;
}

- (Session *)aliceSession {
    return nil;//return [[FreeKeySessionManager sharedManager] processNewKeyExchange:_bobPreKey localUser:_alice remoteUser:_bob];
}

- (Session *)bobSession {
    return nil;//return [[FreeKeySessionManager sharedManager] processNewKeyExchange:[self aliceSession].preKeyExchange localUser:_bob remoteUser:_alice];
}

@end
