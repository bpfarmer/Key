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
#import "KDevice.h"

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
    /*NSString *countSessionsSQL = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE receiver_id = ?", [Session tableName]];
    NSUInteger count = [[KStorageManager sharedManager] queryCount:^NSUInteger(FMDatabase *database) {
        return [database intForQuery:countSessionsSQL, remoteUser.uniqueId];
    }];*/
    Session *session = [Session findByDictionary:@{@"receiverId" : remoteUser.uniqueId}];
    if(session != nil) [resultSource trySetResult:session];
    else {
        TOCFuture *futureResponse = [localUser asyncRetrieveKeyExchangeWithRemoteUser:remoteUser];
        [futureResponse thenDo:^(Session *session) {
            [resultSource trySetResult:session];
        }];
    }
    return resultSource.future;
}

- (TOCFuture *)sessionWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser deviceId:(NSString *)deviceId{
    TOCFutureSource *resultSource = [TOCFutureSource new];
    /*NSString *countSessionsSQL = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE receiver_id = ?", [Session tableName]];
     NSUInteger count = [[KStorageManager sharedManager] queryCount:^NSUInteger(FMDatabase *database) {
     return [database intForQuery:countSessionsSQL, remoteUser.uniqueId];
     }];*/
    Session *session = [Session findByDictionary:@{@"receiverId" : remoteUser.uniqueId, @"deviceId" : deviceId}];
    if(session != nil) [resultSource trySetResult:session];
    else {
        TOCFuture *futureResponse = [localUser asyncRetrieveKeyExchangeWithRemoteUser:remoteUser deviceId:deviceId];
        [futureResponse thenDo:^(Session *session) {
            [resultSource trySetResult:session];
        }];
    }
    return resultSource.future;
}

- (Session *)processNewKeyExchange:(NSObject *)keyExchange localUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    NSLog(@"KEY EXCHANGE: %@", keyExchange);
    NSString *senderDeviceId = localUser.currentDevice.deviceId;
    if([keyExchange isKindOfClass:[PreKey class]]) {
        PreKey *preKey = (PreKey *)keyExchange;
        Session *session = [[Session alloc] initWithSenderId:localUser.uniqueId receiverId:remoteUser.uniqueId senderDeviceId:senderDeviceId receiverDeviceId:preKey.deviceId];
        [session addPreKey:preKey ourBaseKey:[Curve25519 generateKeyPair]];
        [SendPreKeyExchangeRequest makeRequestWithPreKeyExchange:session.preKeyExchange];
        return session;
    }else if([keyExchange isKindOfClass:[PreKeyExchange class]]) {
        PreKeyExchange *preKeyExchange = (PreKeyExchange *)keyExchange;
        Session *session = [[Session alloc] initWithSenderId:localUser.uniqueId receiverId:remoteUser.uniqueId senderDeviceId:senderDeviceId receiverDeviceId:preKeyExchange.senderDeviceId];
        PreKey *ourPreKey = [PreKey findById:(NSString *)((PreKeyExchange *)keyExchange).signedTargetPreKeyId];
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
