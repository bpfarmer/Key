//
//  SendMessageRequest.m
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "SendMessageRequest.h"
#import "CollapsingFutures.h"

@implementation SendMessageRequest

- (instancetype)initWithSendableMessage:(id<KSendable>)message {
    NSDictionary *parameters = @{kMessageAlias : [super toDictionary:message]};
    return [super initWithHttpMethod:PUT endpoint:[super urlForEndpoint:kMessageEndpoint] parameters:parameters];
}

+ (TOCFuture *)makeRequestWithSendableMessage:(id<KSendable>)message {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    SendMessageRequest *request = [[SendMessageRequest alloc] initWithSendableMessage:message];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) =
    ^(AFHTTPRequestOperation *operation, id responseObject){
        [resultSource trySetResult:responseObject];
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) =
    ^(AFHTTPRequestOperation *operation, NSError *error){
        [resultSource trySetFailure:error];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}

@end
