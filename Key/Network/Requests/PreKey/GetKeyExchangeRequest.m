//
//  GetKeyExchangeRequest.m
//  Key
//
//  Created by Brendan Farmer on 3/27/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "GetKeyExchangeRequest.h"
#import "KUser.h"
#import "CollapsingFutures.h"
#import "KStorageManager.h"
#import "PreKey.h"
#import "PreKeyExchange.h"
#import "FreeKey.h"
#import "Session.h"
#import "KAccountManager.h"
#import <25519/Curve25519.h>
#import "KeyExchange.h"

@implementation GetKeyExchangeRequest

- (instancetype)initWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser deviceId:(NSString *)deviceId{
    NSDictionary *parameters = @{kPreKeyLocalUserId : localUser.uniqueId, kPreKeyRemoteUserId : remoteUser.uniqueId, kPreKeyRemoteDeviceId : deviceId, kPreKeyLocalDeviceId : localUser.currentDeviceId};
    return [super initWithHttpMethod:GET endpoint:kPreKeyDeviceEndpoint parameters:parameters];
}

+ (TOCFuture *)makeRequestWithRemoteDeviceId:(NSString *)remoteDeviceId {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    KUser *localUser = [KAccountManager sharedManager].user;
    KUser *remoteUser = [KUser findById:[remoteDeviceId componentsSeparatedByString:@"_"].firstObject];
    GetKeyExchangeRequest *request = [[GetKeyExchangeRequest alloc] initWithLocalUser:localUser remoteUser:remoteUser deviceId:remoteDeviceId];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        NSObject *keyExchange = [request createKeyExchangeFromDictionary:[request base64DecodedDictionary:responseObject]];
        Session *session = [FreeKey processNewKeyExchange:keyExchange localDeviceId:[localUser.currentDeviceId copy] localIdentityKey:[localUser.identityKey copy]];
        [resultSource trySetResult:session];
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error){
        [resultSource trySetFailure:error];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}

- (KeyExchange *)createKeyExchangeFromDictionary:(NSDictionary *)dictionary {
    KeyExchange *keyExchange = nil;
    if(dictionary[kPreKeyExchangeRemoteAlias]) {
        PreKeyExchange *preKeyExchange = [[PreKeyExchange alloc] init];
        [preKeyExchange setValuesForKeysWithDictionary:dictionary[kPreKeyExchangeRemoteAlias]];
        keyExchange = preKeyExchange;
    }else if(dictionary[kPreKeyRemoteAlias]) {
        PreKey *preKey = [[PreKey alloc] init];
        [preKey setValuesForKeysWithDictionary:dictionary[kPreKeyRemoteAlias]];
        keyExchange = preKey;
    }
    return keyExchange;
}

@end
