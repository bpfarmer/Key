//
//  RegisterUsernameRequest.m
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "RegisterUsernameRequest.h"
#import "CollapsingFutures.h"
#import "KUser.h"
#import "HttpManager.h"

#define kUserEndpoint @"user.json"
#define kUserUsername @"username"
#define kUserAlias @"user"
#define kUserUsername @"username"

@implementation RegisterUsernameRequest

- (instancetype)initWithUser:(KUser *)user {
    NSDictionary *parameters = @{kUserUsername : user.username};
    return [super initWithHttpMethod:PUT endpoint:kUserEndpoint parameters:parameters];
}

+ (TOCFuture *)makeRequestWithUser:(KUser *)user {
    CFErrorRef registerError = nil;
    TOCFutureSource *resultSource = [TOCFutureSource new];
    RegisterUsernameRequest *request = [[RegisterUsernameRequest alloc] initWithUser:user];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) =
    ^(AFHTTPRequestOperation *operation, id responseObject){
        [user setUsername:responseObject[kUserAlias][kUserUsername]];
        [resultSource trySetResult:user];
    };
    void (^failure)(AFHTTPRequestOperation *operation, id responseObject) =
    ^(AFHTTPRequestOperation *operation, id responseObject){
        [resultSource trySetFailure:(__bridge id)registerError];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}

@end
