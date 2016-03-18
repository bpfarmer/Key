//
//  SendPreKeysRequest.m
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "SendPreKeysRequest.h"
#import "CollapsingFutures.h"

@implementation SendPreKeysRequest

- (instancetype)initWithPreKeys:(NSArray *)preKeys {
    NSDictionary *parameters = @{ kPreKeyAlias : preKeys };
    NSLog(@"PREKEY PARAMS: %@", [super base64EncodedDictionary:parameters]);
    return [super initWithHttpMethod:PUT endpoint:kPreKeyEndpoint parameters:[super base64EncodedDictionary:parameters]];
}

+ (TOCFuture *)makeRequestWithPreKeys:(NSArray *)preKeys {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    SendPreKeysRequest *request = [[SendPreKeysRequest alloc] initWithPreKeys:preKeys];
    
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
