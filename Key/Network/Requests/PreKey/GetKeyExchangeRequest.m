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

- (instancetype)initWithLocalDeviceId:(NSString *)localDeviceId remoteDeviceId:(NSString *)remoteDeviceId{
    NSDictionary *parameters = @{kPreKeyLocalUserId : localDeviceId, kPreKeyRemoteUserId : remoteDeviceId};
    return [super initWithHttpMethod:GET endpoint:kPreKeyEndpoint parameters:parameters];
}

+ (TOCFuture *)makeRequestWithRemoteDeviceId:(NSString *)remoteDeviceId {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    KUser *localUser = [KAccountManager sharedManager].user;
    GetKeyExchangeRequest *request = [[GetKeyExchangeRequest alloc] initWithLocalDeviceId:localUser.currentDeviceId remoteDeviceId:remoteDeviceId];
    NSLog(@"MAKING REQUEST TO SERVER FOR KEY EXCHANGE: %@", request.parameters);
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        NSLog(@"RETRIEVED KEY EXCHANGE: %@", responseObject);
        NSObject *keyExchange = [request createKeyExchangeFromDictionary:[request base64DecodedDictionary:responseObject]];
        [resultSource trySetResult:keyExchange];
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
        NSLog(@"RECOGNIZING KEY EXCHANGE AS PREKEY");
        PreKey *preKey = [[PreKey alloc] init];
        [preKey setValuesForKeysWithDictionary:dictionary[kPreKeyRemoteAlias]];
        keyExchange = preKey;
    }
    NSLog(@"CREATED KEY EXCHANGE: %@", keyExchange);
    return keyExchange;
}

@end
