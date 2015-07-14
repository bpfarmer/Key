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

- (TOCFuture *)sessionWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    Session *session = [Session findByDictionary:@{@"receiverId" : remoteUser.uniqueId}];
    if(session) {
        [resultSource trySetResult:session];
    }else {
        TOCFuture *futureResponse = [localUser asyncRetrieveKeyExchangeWithRemoteUser:remoteUser];
        [futureResponse thenDo:^(Session *session) {
            [resultSource trySetResult:session];
        }];
    }
    
    return resultSource.future;
}

- (Session *)processNewKeyExchange:(NSObject *)keyExchange localUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    if([keyExchange isKindOfClass:[PreKey class]]) {
        Session *session = [[Session alloc] initWithSenderId:localUser.uniqueId receiverId:remoteUser.uniqueId];
        [session addPreKey:(PreKey *)keyExchange ourBaseKey:[Curve25519 generateKeyPair]];
        return session;
    }else if([keyExchange isKindOfClass:[PreKeyExchange class]]) {
        Session *session = [[Session alloc] initWithSenderId:localUser.uniqueId receiverId:remoteUser.uniqueId];
        PreKey *ourPreKey = [PreKey findById:((PreKeyExchange *)keyExchange).signedTargetPreKeyId];
        if(ourPreKey) {
            [session addOurPreKey:ourPreKey preKeyExchange:(PreKeyExchange *)keyExchange];
            return session;
        }else {
            NSLog(@"REFERENCE TO A NON-EXISTENT PRE KEY");
            return nil;
        }
    }else {
        return nil;
    }
}
@end
