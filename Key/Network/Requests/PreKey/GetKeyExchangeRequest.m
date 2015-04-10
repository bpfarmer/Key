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

@implementation GetKeyExchangeRequest

- (instancetype)initWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    NSDictionary *parameters = @{kPreKeyLocalUserId : localUser.uniqueId, kPreKeyRemoteUserId : remoteUser.uniqueId};
    return [super initWithHttpMethod:GET endpoint:kPreKeyEndpoint parameters:parameters];
}

+ (TOCFuture *)makeRequestWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    GetKeyExchangeRequest *request = [[GetKeyExchangeRequest alloc] initWithLocalUser:localUser remoteUser:remoteUser];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) =
    ^(AFHTTPRequestOperation *operation, id responseObject){
        NSLog(@"KEY EXCHANGE RESPONSE OBJECT: %@", responseObject);
        [resultSource trySetResult:[request createKeyExchangeFromDictionary:[request base64DecodedDictionary:responseObject]]];
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) =
    ^(AFHTTPRequestOperation *operation, NSError *error){
        NSLog(@"KEY EXCHANGE ERROR: %@", error);
        [resultSource trySetFailure:error];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}

- (NSObject *)createKeyExchangeFromDictionary:(NSDictionary *)dictionary {
    NSObject *keyExchange;
    if(dictionary[kPreKeyExchangeRemoteAlias]) {
        PreKeyExchange *preKeyExchange =
        [FreeKeyResponseHandler createPreKeyExchangeFromRemoteDictionary:dictionary[kPreKeyExchangeRemoteAlias]];
        
        [[KStorageManager sharedManager] setObject:preKeyExchange
                                            forKey:preKeyExchange.senderId
                                      inCollection:kPreKeyExchangeCollection];
        keyExchange = preKeyExchange;
    }else if(dictionary[kPreKeyRemoteAlias]) {
        PreKey *preKey =
        [FreeKeyResponseHandler createPreKeyFromRemoteDictionary:dictionary[kPreKeyRemoteAlias]];
        
        [[KStorageManager sharedManager] setObject:preKey
                                            forKey:preKey.userId
                                      inCollection:kTheirPreKeyCollection];
        keyExchange = preKey;
    }
    return keyExchange;
}

@end
