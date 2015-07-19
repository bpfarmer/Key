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
#import "FreeKeyNetworkManager.h"
#import "KStorageManager.h"
#import "PreKey.h"
#import "PreKeyExchange.h"
#import "FreeKey.h"
#import "FreeKeyResponseHandler.h"
#import "FreeKeySessionManager.h"
#import "Session.h"

@implementation GetKeyExchangeRequest

- (instancetype)initWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    NSDictionary *parameters = @{kPreKeyLocalUserId : localUser.uniqueId, kPreKeyRemoteUserId : remoteUser.uniqueId};
    return [super initWithHttpMethod:GET endpoint:kPreKeyEndpoint parameters:parameters];
}

- (instancetype)initWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser deviceId:(NSString *)deviceId{
    NSDictionary *parameters = @{kPreKeyLocalUserId : localUser.uniqueId, kPreKeyRemoteUserId : remoteUser.uniqueId};
    return [super initWithHttpMethod:GET endpoint:kPreKeyDeviceEndpoint parameters:parameters];
}

+ (TOCFuture *)makeRequestWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    NSLog(@"LOCAL USER: %@", localUser.uniqueId);
    NSLog(@"REMOTE USER: %@", remoteUser.uniqueId);
    TOCFutureSource *resultSource = [TOCFutureSource new];
    GetKeyExchangeRequest *request = [[GetKeyExchangeRequest alloc] initWithLocalUser:localUser remoteUser:remoteUser];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        NSLog(@"-- PKE RESPONSE OBJECT: %@ --", responseObject);
        for(NSDictionary *keyDict in responseObject[@"keys"]) {
            NSObject *keyExchange = [request createKeyExchangeFromDictionary:[request base64DecodedDictionary:keyDict]];
            [remoteUser setHasLocalPreKey:YES];
            [remoteUser save];
            Session *session = [[FreeKeySessionManager sharedManager] processNewKeyExchange:keyExchange localUser:localUser remoteUser:remoteUser];
            [resultSource trySetResult:session];
        }
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error){
        [resultSource trySetFailure:error];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}

+ (TOCFuture *)makeRequestWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser deviceId:(NSString *)deviceId {
    NSLog(@"LOCAL USER: %@", localUser.uniqueId);
    NSLog(@"REMOTE USER: %@", remoteUser.uniqueId);
    NSLog(@"DEVICE ID: %@", deviceId);
    TOCFutureSource *resultSource = [TOCFutureSource new];
    GetKeyExchangeRequest *request = [[GetKeyExchangeRequest alloc] initWithLocalUser:localUser remoteUser:remoteUser deviceId:deviceId];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        NSLog(@"-- PKE RESPONSE OBJECT: %@ --", responseObject);
        NSObject *keyExchange = [request createKeyExchangeFromDictionary:[request base64DecodedDictionary:responseObject]];
        [remoteUser setHasLocalPreKey:YES];
        [remoteUser save];
        Session *session = [[FreeKeySessionManager sharedManager] processNewKeyExchange:keyExchange localUser:localUser remoteUser:remoteUser];
        [resultSource trySetResult:session];
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error){
        [resultSource trySetFailure:error];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}

- (NSObject *)createKeyExchangeFromDictionary:(NSDictionary *)dictionary {
    NSObject *keyExchange;
    if(dictionary[kPreKeyExchangeRemoteAlias]) {
        PreKeyExchange *preKeyExchange = [FreeKeyResponseHandler createPreKeyExchangeFromRemoteDictionary:dictionary[kPreKeyExchangeRemoteAlias]];
        
        [preKeyExchange save];
        NSLog(@"-- PREKEY EXCHANGE BASE KEY: %@", preKeyExchange.sentSignedBaseKey);
        NSLog(@"-- PREKEY EXCHANGE ID KEY: %@", preKeyExchange.senderIdentityPublicKey);
        keyExchange = preKeyExchange;
    }else if(dictionary[kPreKeyRemoteAlias]) {
        PreKey *preKey =
        [FreeKeyResponseHandler createPreKeyFromRemoteDictionary:dictionary[kPreKeyRemoteAlias]];
        
        [preKey save];
        keyExchange = preKey;
    }
    return keyExchange;
}

@end
