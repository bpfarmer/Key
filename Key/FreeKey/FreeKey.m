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
#import "Session.h"
#import "PreKeyExchange.h"
#import "HttpManager.h"

#define kPreKeyCollection @"PreKey"
#define kSessionCollection @"Session"
#define kPreKeyExchangeCollection @"PreKeyExchange"
#define kPreKeyRemoteAlias @"PreKey"

@implementation FreeKey

#pragma  mark - PreKey Generation
- (NSArray *)generatePreKeysForUser:(KUser *)user {
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

- (void)sendPreKeysToServer:(NSArray *)preKeys {
    
}

#pragma mark - Encryption and Decryption Queue

#pragma mark - Encryption and Decryption Wrappers
- (EncryptedMessage *)encryptObject:(id<KEncryptable>)object
                          localUser:(KUser *)localUser
                        recipientId:(NSString *)recipientId {
    Session *session = (Session *)[[KStorageManager sharedManager] objectForKey:recipientId
                                                                   inCollection:kSessionCollection];
    if(!session) {
        PreKeyExchange *preKeyExchange = (PreKeyExchange *)
            [[KStorageManager sharedManager] objectForKey:recipientId inCollection:kPreKeyExchangeCollection];
        if(preKeyExchange) {
            session = [self createSessionFromUser:localUser withPreKeyExchange:preKeyExchange];
        }else {
            PreKey *preKey = [self getPreKeyForRecipientId:recipientId];
            if(!preKey) {
                [self getRemotePreKey:recipientId];
                return nil;
            }else {
                session = [self createSessionFromUser:localUser withPreKey:preKey];
            }
        }
    }
    NSData *serializedData = [NSKeyedArchiver archivedDataWithRootObject:object];
    return [session encryptMessage:serializedData];
}

- (id <KEncryptable>)decryptEncryptedMessage:(EncryptedMessage *)encryptedMessage
                                    localUser:(KUser *)localUser
                                    senderId:(NSString *)senderId {
    
    Session *session = (Session *)[[KStorageManager sharedManager] objectForKey:senderId
                                                                   inCollection:kSessionCollection];
    if(!session) {
        PreKeyExchange *preKeyExchange = (PreKeyExchange *)[[KStorageManager sharedManager] objectForKey:senderId inCollection:kPreKeyExchangeCollection];
        
        session = [self createSessionFromUser:localUser withPreKeyExchange:preKeyExchange];
    }
    NSData *decryptedData = [session decryptMessage:encryptedMessage];
    return [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
}

#pragma mark - Session Generation
- (Session *)createSessionFromUser:(KUser *)localUser withPreKey:(PreKey *)preKey {
    Session *session = [[Session alloc] initWithReceiverId:preKey.userId identityKey:localUser.identityKey];
    [session addPreKey:preKey];
    return session;
}

- (Session *)createSessionFromUser:(KUser *)localUser withPreKeyExchange:(PreKeyExchange *)preKeyExchange {
    Session *session  = [[Session alloc] initWithReceiverId:preKeyExchange.senderId identityKey:localUser.identityKey];
    PreKey *ourPreKey = [[KStorageManager sharedManager] objectForKey:preKeyExchange.signedTargetPreKeyId
                                                         inCollection:kPreKeyCollection];
    [session addOurPreKey:ourPreKey preKeyExchange:preKeyExchange];
    return session;
}

#pragma mark - Retrieving PreKeys for Remote Users
- (PreKey *)getPreKeyForRecipientId:(NSString *)recipientId {
    KUser *user = (KUser *)[[KStorageManager sharedManager] objectForKey:recipientId inCollection:[KUser collection]];
    return user.preKey;
}

- (void)getRemotePreKey:(NSString *)recipientId {
    NSDictionary *query = @{@"object" : kPreKeyRemoteAlias,
                            @"query" : @{@"userId" : recipientId}};
    [[HttpManager sharedManager] get:query];
}

@end
