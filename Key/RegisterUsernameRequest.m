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

@implementation RegisterUsernameRequest

- (instancetype)initWithUser:(KUser *)user {
    NSDictionary *parameters = @{kUserAlias : @{kUserUsername : user.username,
                                                kUserPasswordCrypt: user.passwordCrypt}};
    return [super initWithHttpMethod:PUT endpoint:[super urlForEndpoint:kUserEndpoint] parameters:parameters];
}

+ (TOCFuture *)makeRequestWithUser:(KUser *)user {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    RegisterUsernameRequest *request = [[RegisterUsernameRequest alloc] initWithUser:user];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) =
    ^(AFHTTPRequestOperation *operation, id responseObject){
        [user setUniqueId:responseObject[kUserAlias][kUserUniqueId]];
        [resultSource trySetResult:user];
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) =
    ^(AFHTTPRequestOperation *operation, NSError *error){
        [resultSource trySetFailure:error];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}

@end
