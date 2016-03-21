//
//  SendPreKeyExchangeRequest.m
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "SendPreKeyExchangeRequest.h"
#import "CollapsingFutures.h"

@implementation SendPreKeyExchangeRequest

- (instancetype)initWithPreKeyExchange:(PreKeyExchange *)preKeyExchange {
    NSDictionary *parameters = @{ kPreKeyExchangeAlias : [super toDictionary:(id <KSendable>)preKeyExchange] };
    return [super initWithHttpMethod:PUT endpoint:kPreKeyExchangeEndpoint parameters:[super base64EncodedDictionary:parameters]];
}

+ (TOCFuture *)makeRequestWithPreKeyExchange:(PreKeyExchange *)preKeyExchange {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    SendPreKeyExchangeRequest *request = [[SendPreKeyExchangeRequest alloc] initWithPreKeyExchange:preKeyExchange];
    
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        [resultSource trySetResult:@YES];
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error){
        [resultSource trySetFailure:error];
    };
    
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}

@end
