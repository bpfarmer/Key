//
//  GetMessagesRequest.m
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "GetMessagesRequest.h"
#import "CollapsingFutures.h"
#import "FreeKeyNetworkManager.h"
#import "FreeKeyResponseHandler.h"
#import "KAccountManager.h"
#import "KUser.h"

@implementation GetMessagesRequest

- (instancetype)initWIthCurrentUserId:(NSString *)currentUserId {
    NSDictionary *parameters = @{kMessageCurrentUserId : currentUserId};
    return [super initWithHttpMethod:GET endpoint:[super urlForEndpoint:kFeedEndpoint] parameters:parameters];
}

+ (TOCFuture *)makeRequestWithCurrentUserId:(NSString *)currentUserId {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    GetMessagesRequest *request = [[GetMessagesRequest alloc] initWIthCurrentUserId:currentUserId];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) =
    ^(AFHTTPRequestOperation *operation, id responseObject){
        NSLog(@"RESPONSE OBJECT: %@", responseObject);
        [request receiveMessages:[request base64DecodedDictionary:responseObject]];
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) =
    ^(AFHTTPRequestOperation *operation, NSError *error){
        NSLog(@"ERROR: %@", error);
        [resultSource trySetFailure:error];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}

- (void)receiveMessages:(NSDictionary *)messages {
    if(messages[kPreKeyExchangeRemoteAlias]) {
        if([messages[kPreKeyExchangeRemoteAlias] isKindOfClass:[NSDictionary class]]) {
            [FreeKeyResponseHandler createPreKeyExchangeFromRemoteDictionary:messages[kPreKeyExchangeRemoteAlias]];
        }else {
            for(NSDictionary *msg in messages[kPreKeyExchangeRemoteAlias]) {
                [FreeKeyResponseHandler createPreKeyExchangeFromRemoteDictionary:msg];
            }
        }
    }
    KUser *localUser = [KAccountManager sharedManager].user;
    if(messages[kEncryptedMessageRemoteAlias]) {
        if([messages[kEncryptedMessageRemoteAlias] isKindOfClass:[NSDictionary class]]) {
            EncryptedMessage *message =
            [FreeKeyResponseHandler createEncryptedMessageFromRemoteDictionary:messages[kEncryptedMessageRemoteAlias]];
            [[FreeKeyNetworkManager sharedManager] enqueueDecryptableMessage:message toLocalUser:localUser];
        }else {
            for(NSDictionary *msg in messages[kEncryptedMessageRemoteAlias]) {
                EncryptedMessage *message = [FreeKeyResponseHandler createEncryptedMessageFromRemoteDictionary:msg];
                [[FreeKeyNetworkManager sharedManager] enqueueDecryptableMessage:message toLocalUser:localUser];
            }
        }
    }
}

@end
