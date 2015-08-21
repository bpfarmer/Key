//
//  PushTokenRequest.m
//  Key
//
//  Created by Brendan Farmer on 3/31/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "SendPushTokenRequest.h"
#import "CollapsingFutures.h"

@implementation SendPushTokenRequest

- (instancetype)initWithDeviceToken:(NSData *)deviceToken uniqueId:(NSString *)uniqueId {
    NSDictionary *parameters = @{ kPushTokenDeviceToken : deviceToken,
                                  kPushTokenUniqueId    : uniqueId};
    return [super initWithHttpMethod:PUT endpoint:kPushTokenEndpoint parameters:parameters];
}

- (instancetype)initWithDeviceToken:(NSData *)deviceToken username:(NSString *)username {
    NSDictionary *parameters = @{ kPushTokenDeviceToken : deviceToken,
                                  kPushTokenUsername    : username};
    return [super initWithHttpMethod:PUT endpoint:kPushTokenEndpoint parameters:parameters];
}

+ (TOCFuture *)makeRequestWithDeviceToken:(NSData *)deviceToken uniqueId:(NSString *)uniqueId {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    SendPushTokenRequest *request = [[SendPushTokenRequest alloc] initWithDeviceToken:deviceToken uniqueId:uniqueId];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) =
    ^(AFHTTPRequestOperation *operation, id responseObject){
        [resultSource trySetResult:@YES];
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) =
    ^(AFHTTPRequestOperation *operation, NSError *error){
        NSLog(@"ERROR: %@", error);
        [resultSource trySetFailure:error];
    };
    NSLog(@"PARAMETERS: %@", request.parameters);
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
    
}

+ (TOCFuture *)makeRequestWithDeviceToken:(NSData *)deviceToken username:(NSString *)username {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    SendPushTokenRequest *request = [[SendPushTokenRequest alloc] initWithDeviceToken:deviceToken username:username];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) =
    ^(AFHTTPRequestOperation *operation, id responseObject){
        [resultSource trySetResult:@YES];
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) =
    ^(AFHTTPRequestOperation *operation, NSError *error){
        NSLog(@"ERROR: %@", error);
        [resultSource trySetFailure:error];
    };
    NSLog(@"PARAMETERS: %@", request.parameters);
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;

}

@end
