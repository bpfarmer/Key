//
//  FreeKey.m
//  Key
//
//  Created by Brendan Farmer on 3/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "FreeKey.h"
#import "PreKey.h"
#import "KUser.h"
#import <25519/Curve25519.h>
#import <25519/Ed25519.h>
#import "IdentityKey.h"


@implementation FreeKey

+ (void)setupPreKeysForUser:(KUser *)user {
    int index = 0;
    NSMutableSet *preKeys;
    ECKeyPair *identityKeyPair = user.identityKey.keyPair;
    //TODO: why the distinction between PreKeys and signed PreKeys?
    while(index < 100) {
        ECKeyPair *baseKeyPair = [Curve25519 generateKeyPair];
        [preKeys addObject:[[PreKey alloc] initWithUserId:user.uniqueId
                                                 deviceId:nil
                                                 preKeyId:[self preKeyId:user]
                                             preKeyPublic:baseKeyPair.publicKey
                                       signedPreKeyPublic:baseKeyPair.publicKey
                                           signedPreKeyId:nil
                                    signedPreKeySignature:[Ed25519 sign:baseKeyPair.publicKey withKeyPair:identityKeyPair]
                                              identityKey:identityKeyPair.publicKey
                                              baseKeyPair:baseKeyPair]];
    }
}
         
+ (NSString *)preKeyId:(KUser *)user {
    return nil;
}

+ (EncryptedMessage *)encryptObject:(id<KEncryptable>)object toUser:(NSString *)userId {
    return nil;
}

+ (id <KEncryptable>)decryptEncryptedMessage:(EncryptedMessage *)encryptedMessage fromUser:(NSString *)userId {
    return nil;
}

+ (void)respondToPreKeyExchange:(PreKeyExchange *)preKeyExchange {
    
}

+ (void)respondToPreKeyRecript:(PreKeyReceipt *)preKeyReceipt {
    
}

// TODO: write methods for session serialization and persistence

@end
