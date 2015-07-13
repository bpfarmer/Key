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
#import "CollapsingFutures.h"
#import "KAccountManager.h"
#import "SendPreKeyExchangeRequest.h"

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

- (TOCFuture *)sessionForRemoteUserId:(NSString *)remoteUserId {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    KUser *localUser  = [KAccountManager sharedManager].user;

    KUser *remoteUser = [KUser findById:remoteUserId];
    if(remoteUser) {
        [resultSource trySetResult:[self sessionWithLocalUser:localUser remoteUser:remoteUser]];
    }else {
        TOCFuture *futureUser = [KUser asyncRetrieveWithUniqueId:remoteUserId];
        [futureUser thenDo:^(KUser *remoteUser) {
            [resultSource trySetResult:[self sessionWithLocalUser:localUser remoteUser:remoteUser]];
        }];
    }
    return resultSource.future;
}

- (TOCFuture *)sessionWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    Session *session = [Session findByDictionary:@{@"receiverId" : remoteUser.uniqueId}];
    if(session) {
        [resultSource trySetResult:session];
    }else {
        if(remoteUser.hasLocalPreKey) {
            Session *session = [self createSessionWithLocalUser:localUser remoteUser:remoteUser];
            if(session) [resultSource trySetResult:session];
        }else {
            TOCFuture *futureResponse = [localUser asyncRetrieveKeyExchangeWithRemoteUser:remoteUser];
            [futureResponse thenDo:^(Session *session) {
                [resultSource trySetResult:session];
            }];
        }
    }
    
    return resultSource.future;
}

- (Session *)createSessionWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    PreKeyExchange *preKeyExchange = [self getPreKeyExchangeForUserId:remoteUser.uniqueId];
    
    if(!preKeyExchange) {
        PreKey *preKey = [self getPreKeyForUserId:remoteUser.uniqueId];
        
        return [self createSessionWithLocalUser:localUser remoteUser:remoteUser ourBaseKey:[Curve25519 generateKeyPair] theirPreKey:preKey];
    }else {
        PreKey *targetPreKey = [self getPreKeyWithId:preKeyExchange.signedTargetPreKeyId];
        return [self createSessionWithLocalUser:localUser remoteUser:remoteUser ourPreKey:targetPreKey theirPreKeyExchange:preKeyExchange];
    }
}

- (Session *)createSessionWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser ourBaseKey:(ECKeyPair *)ourBaseKey theirPreKey:(PreKey *)theirPreKey {
    Session *session = [[Session alloc] initWithSenderId:localUser.uniqueId receiverId:remoteUser.uniqueId];
    [session addPreKey:theirPreKey ourBaseKey:ourBaseKey];
    [SendPreKeyExchangeRequest makeRequestWithPreKeyExchange:session.preKeyExchange];
    [session save];
    return session;
}

- (Session *)createSessionWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser ourPreKey:(PreKey *)ourPreKey theirPreKeyExchange:(PreKeyExchange *)theirPreKeyExchange {
    Session *session = [[Session alloc] initWithSenderId:localUser.uniqueId receiverId:remoteUser.uniqueId];
    [session addOurPreKey:ourPreKey preKeyExchange:theirPreKeyExchange];
    [session save];
    return session;
}

- (Session *)processNewKeyExchange:(id)keyExchange localUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    if([keyExchange isKindOfClass:[PreKey class]]) {
        return [self processNewPreKey:keyExchange localUser:localUser remoteUser:remoteUser];
    }else if([keyExchange isKindOfClass:[PreKeyExchange class]]) {
        return [self processNewKeyExchange:keyExchange localUser:localUser remoteUser:remoteUser];
    }else {
        return nil;
    }
}

- (Session *)processNewPreKey:(PreKey *)preKey localUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    Session *session  = [Session findByDictionary:@{@"receiverId" : remoteUser.uniqueId}];
    
    if(!session) {
        PreKeyExchange *previousExchange = [self getPreKeyExchangeForUserId:remoteUser.uniqueId];
        
        if(previousExchange) return [self processNewPreKeyExchange:previousExchange localUser:localUser remoteUser:remoteUser];
        
        session = [self createSessionWithLocalUser:localUser remoteUser:remoteUser ourBaseKey:[Curve25519 generateKeyPair] theirPreKey:preKey];
        
        PreKeyExchange *preKeyExchange = [session preKeyExchange];
        [session save];
        [preKeyExchange save];
    }
    return session;
}

- (Session *)processNewPreKeyExchange:(PreKeyExchange *)preKeyExchange localUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    Session *session  = [Session findByDictionary:@{@"receiverId" : remoteUser.uniqueId}];
    
    if(!session) {
        PreKey *ourPreKey = [PreKey findById:preKeyExchange.signedTargetPreKeyId];
        if(ourPreKey) {
            session = [self createSessionWithLocalUser:localUser remoteUser:remoteUser ourPreKey:ourPreKey theirPreKeyExchange:preKeyExchange];
            [session save];
        }
    }
    return session;
}

- (PreKey *)getPreKeyForUserId:(NSString *)userId {
    return [PreKey findByDictionary:@{@"userId" : userId}];
}

- (PreKey *)getPreKeyWithId:(NSString *)uniqueId {
    return [PreKey findById:uniqueId];
}

- (PreKeyExchange *)getPreKeyExchangeForUserId:(NSString *)userId {
    return [PreKeyExchange findByDictionary:@{@"senderId" : userId}];
}

@end
