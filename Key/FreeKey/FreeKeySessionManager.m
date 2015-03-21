//
//  FreeKeySessionManager.m
//  Key
//
//  Created by Brendan Farmer on 3/20/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "FreeKeySessionManager.h"
#import <25519/Curve25519.h>
#import <25519/Ed25519.h>
#import "HttpManager.h"
#import "KUser.h"
#import "PreKey.h"
#import "KStorageManager.h"
#import "IdentityKey.h"
#import "FreeKey.h"
#import "NSData+Base64.h"
#import "Session.h"
#import "IdentityKey.h"
#import "PreKeyExchange.h"
#import "FreeKeyNetworkManager.h"

@implementation FreeKeySessionManager

#pragma mark - Creating Sessions

+ (instancetype)sharedManager {
    static FreeKeySessionManager *sharedMyManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (Session *)sessionWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    return (Session *)[[KStorageManager sharedManager] objectForKey:remoteUser.uniqueId inCollection:kSessionCollection];
}

- (Session *)createSessionWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    PreKey *preKey = [self getPreKeyForUserId:remoteUser.uniqueId];
    if(preKey) {
        return [self createSessionWithLocalUser:localUser
                                     remoteUser:remoteUser
                                     ourBaseKey:[Curve25519 generateKeyPair]
                                    theirPreKey:preKey];
    }else {
        PreKeyExchange *preKeyExchange = [self getPreKeyExchangeForUserId:remoteUser.uniqueId];
        if(!preKeyExchange) {
            [[FreeKeyNetworkManager sharedManager] getPreKeyWithRemoteUser:remoteUser];
            return nil;
        }else {
            PreKey *ourPreKey = [[KStorageManager sharedManager] objectForKey:preKeyExchange.signedTargetPreKeyId
                                                                 inCollection:kOurPreKeyCollection];
            if(!ourPreKey) return nil;
            return [self createSessionWithLocalUser:localUser
                                         remoteUser:remoteUser
                                          ourPreKey:ourPreKey
                                theirPreKeyExchange:preKeyExchange];
        }
    }
}

- (Session *)createSessionWithLocalUser:(KUser *)localUser
                             remoteUser:(KUser *)remoteUser
                             ourBaseKey:(ECKeyPair *)ourBaseKey
                            theirPreKey:(PreKey *)theirPreKey {
    Session *session = [[Session alloc] initWithReceiverId:remoteUser.uniqueId identityKey:localUser.identityKey];
    [session addPreKey:theirPreKey ourBaseKey:ourBaseKey];
    [[KStorageManager sharedManager] setObject:session forKey:remoteUser.uniqueId inCollection:kSessionCollection];
    return session;
}

- (Session *)createSessionWithLocalUser:(KUser *)localUser
                             remoteUser:(KUser *)remoteUser
                              ourPreKey:(PreKey *)ourPreKey
                    theirPreKeyExchange:(PreKeyExchange *)theirPreKeyExchange {
    Session *session = [[Session alloc] initWithReceiverId:remoteUser.uniqueId identityKey:localUser.identityKey];
    [session addOurPreKey:ourPreKey preKeyExchange:theirPreKeyExchange];
    [[KStorageManager sharedManager] setObject:session forKey:remoteUser.uniqueId inCollection:kSessionCollection];
    return session;
}

#pragma mark - Retrieving PreKeys and PreKeyExchanges for Remote Users
- (PreKey *)getPreKeyForUserId:(NSString *)userId {
    return (PreKey *)[[KStorageManager sharedManager] objectForKey:userId inCollection:kTheirPreKeyCollection];
}

- (PreKeyExchange *)getPreKeyExchangeForUserId:(NSString *)userId {
    return (PreKeyExchange *)[[KStorageManager sharedManager] objectForKey:userId inCollection:kPreKeyExchangeCollection];
}

#pragma mark - Generating PreKeys

- (NSArray *)generatePreKeysForLocalUser:(KUser *)localUser {
    int index = 0;
    NSMutableArray *preKeys = [[NSMutableArray alloc] init];
    while(index < 100) {
        ECKeyPair *baseKeyPair = [Curve25519 generateKeyPair];
        NSString *uniquePreKeyId = [NSString stringWithFormat:@"%@_%f_%d", localUser.uniqueId, [[NSDate date] timeIntervalSince1970], index];
        NSData *preKeySignature = [Ed25519 sign:baseKeyPair.publicKey withKeyPair:localUser.identityKey.keyPair];
        PreKey *preKey = [[PreKey alloc] initWithUserId:localUser.uniqueId
                                               deviceId:@"1"
                                         signedPreKeyId:uniquePreKeyId
                                     signedPreKeyPublic:baseKeyPair.publicKey
                                  signedPreKeySignature:preKeySignature
                                            identityKey:localUser.publicKey
                                            baseKeyPair:baseKeyPair];
        [[KStorageManager sharedManager] setObject:preKey forKey:preKey.signedPreKeyId inCollection:kOurPreKeyCollection];
        [preKeys addObject:[self base64EncodedPreKeyDictionary:preKey]];
        index++;
    }
    return [[NSArray alloc] initWithArray:preKeys];
}

- (NSDictionary *)base64EncodedPreKeyDictionary:(PreKey *)preKey {
    NSMutableDictionary *objectDictionary = [[NSMutableDictionary alloc] init];
    [[PreKey remoteKeys] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSObject *property = [preKey dictionaryWithValuesForKeys:@[obj]][obj];
        if([property isKindOfClass:[NSData class]]) {
            NSData *dataProperty = (NSData *)property;
            NSString *encodedString = [dataProperty base64EncodedString];
            [objectDictionary addEntriesFromDictionary:@{obj : encodedString}];
        }else {
            [objectDictionary addEntriesFromDictionary:@{obj : property}];
        }
        
    }];
    return objectDictionary;
}

@end
