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

- (Session *)processNewPreKey:(PreKey *)preKey localUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    Session *session  = [self sessionWithLocalUser:localUser remoteUser:remoteUser];
    PreKeyExchange *previousExchange = [[KStorageManager sharedManager] objectForKey:remoteUser.uniqueId
                                                                        inCollection:kPreKeyExchangeCollection];
    if(!session && !previousExchange) {
        session = [self createSessionWithLocalUser:localUser
                              remoteUser:remoteUser
                              ourBaseKey:[Curve25519 generateKeyPair]
                             theirPreKey:preKey];
        
        PreKeyExchange *preKeyExchange = [session preKeyExchange];
        [[KStorageManager sharedManager] setObject:session forKey:remoteUser.uniqueId inCollection:kSessionCollection];
        [[KStorageManager sharedManager] setObject:preKeyExchange
                                            forKey:remoteUser.uniqueId
                                      inCollection:kPreKeyExchangeCollection];
        [[FreeKeyNetworkManager sharedManager] sendPreKeyExchange:preKeyExchange toRemoteUser:remoteUser];
    }else if(previousExchange) {
        PreKey *ourPreKey = [[KStorageManager sharedManager] objectForKey:previousExchange.signedTargetPreKeyId
                                                             inCollection:kOurPreKeyCollection];
        session = [self createSessionWithLocalUser:localUser
                                        remoteUser:remoteUser
                                         ourPreKey:ourPreKey
                               theirPreKeyExchange:previousExchange];
        
        [[KStorageManager sharedManager] setObject:session forKey:remoteUser.uniqueId inCollection:kSessionCollection];
    }
    return session;
}

- (Session *)processNewPreKeyExchange:(PreKeyExchange *)preKeyExchange
                            localUser:(KUser *)localUser
                           remoteUser:(KUser *)remoteUser {
    Session *session  = [self sessionWithLocalUser:localUser remoteUser:remoteUser];
    
    if(!session) {
        PreKey *ourPreKey = [[KStorageManager sharedManager] objectForKey:preKeyExchange.signedTargetPreKeyId
                                                             inCollection:kOurPreKeyCollection];
        session = [self createSessionWithLocalUser:localUser
                                        remoteUser:remoteUser
                                         ourPreKey:ourPreKey
                               theirPreKeyExchange:preKeyExchange];
    }
    
    return session;
}

- (PreKey *)getPreKeyForUserId:(NSString *)userId {
    return (PreKey *)[[KStorageManager sharedManager] objectForKey:userId inCollection:kTheirPreKeyCollection];
}

- (PreKeyExchange *)getPreKeyExchangeForUserId:(NSString *)userId {
    return (PreKeyExchange *)[[KStorageManager sharedManager] objectForKey:userId inCollection:kPreKeyExchangeCollection];
}

@end
