//
//  FreeKeyTestExample.m
//  Key
//
//  Created by Brendan Farmer on 3/20/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "FreeKeyTestExample.h"
#import "KUser.h"
#import "IdentityKey.h"
#import <25519/Curve25519.h>
#import <25519/Ed25519.h>
#import "PreKeyExchange.h"
#import "PreKey.h"
#import "Session.h"
#import "FreeKeySessionManager.h"
#import "KStorageManager.h"
#import "KStorageSchema.h"

@implementation FreeKeyTestExample

- (instancetype)init {
    self = [super init];
    [[KStorageManager sharedManager] setDatabaseWithName:@"testDB"];
    [KStorageSchema dropTables];
    [KStorageSchema createTables];
    
    NSString *bobId = @"bobUniqueId";
    NSString *aliceId = @"aliceUniqueId";
    
    _alice = [[KUser alloc] initWithUniqueId:aliceId];
    [_alice setUsername:@"alice"];
    [_alice setupIdentityKey];
    
    _bob   = [[KUser alloc] initWithUniqueId:bobId];
    [_bob setUsername:@"bob"];
    [_bob setupIdentityKey];
    
    _aliceBaseKeyPair = [Curve25519 generateKeyPair];
    _bobBaseKeyPair = [Curve25519 generateKeyPair];
    
    NSData *preKeySignature = [Ed25519 sign:_bobBaseKeyPair.publicKey withKeyPair:_bob.identityKey.keyPair];
    _bobPreKey = [[PreKey alloc] initWithUserId:_bob.uniqueId
                                       deviceId:@"1"
                                 signedPreKeyId:@"1"
                             signedPreKeyPublic:_bobBaseKeyPair.publicKey
                          signedPreKeySignature:preKeySignature
                                    identityKey:_bob.identityKey.publicKey
                                    baseKeyPair:_bobBaseKeyPair];
    [_bobPreKey setUniqueId:@"1"];
    [_bobPreKey save];
    
    NSData *preKeyExchangeSignature = [Ed25519 sign:_aliceBaseKeyPair.publicKey withKeyPair:_alice.identityKey.keyPair];
    _alicePreKeyExchange = [[PreKeyExchange alloc] initWithSenderId:_alice.uniqueId
                                                         receiverId:_bob.uniqueId
                                               signedTargetPreKeyId:@"1"
                                                  sentSignedBaseKey:_aliceBaseKeyPair.publicKey
                                            senderIdentityPublicKey:_alice.identityKey.publicKey
                                          receiverIdentityPublicKey:_bob.identityKey.publicKey
                                                   baseKeySignature:preKeyExchangeSignature];
    
    [_alicePreKeyExchange save];
    
    [_alice save];
    [_bob save];
    
    return self;
}

- (Session *)aliceSession {
    return [[FreeKeySessionManager sharedManager] processNewKeyExchange:_bobPreKey localUser:_alice remoteUser:_bob];
}

- (Session *)bobSession {
    return [[FreeKeySessionManager sharedManager] processNewKeyExchange:[self aliceSession].preKeyExchange localUser:_bob remoteUser:_alice];
}

@end
