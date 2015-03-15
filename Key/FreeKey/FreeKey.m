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
#import "KStorageManager.h"

#define kPreKeyCollection @"PreKey"

@implementation FreeKey

+ (NSArray *)generatePreKeysForUser:(KUser *)user {
    int index = 0;
    NSMutableArray *preKeys;
    while(index < 100) {
        ECKeyPair *baseKeyPair = [Curve25519 generateKeyPair];
        NSString *uniquePreKeyId = [NSString stringWithFormat:@"%@_%f_%d", user.uniqueId, [[NSDate date] timeIntervalSince1970], index];
        NSData *preKeySignature = [Ed25519 sign:baseKeyPair.publicKey withKeyPair:user.identityKey.keyPair];
        PreKey *preKey = [[PreKey alloc] initWithUserId:user.uniqueId
                                                 deviceId:@"1"
                                           signedPreKeyId:uniquePreKeyId
                                       signedPreKeyPublic:baseKeyPair.publicKey
                                    signedPreKeySignature:preKeySignature
                                              identityKey:user.publicKey
                                              baseKeyPair:baseKeyPair];
        [[KStorageManager sharedManager] setObject:preKey forKey:preKey.signedPreKeyId inCollection:kPreKeyCollection];
        [preKeys addObject:preKey];
        index++;
    }
    return [[NSArray alloc] initWithArray:preKeys];
}

+ (void)sendPreKeysToServer:(NSArray *)preKeys {
    
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
