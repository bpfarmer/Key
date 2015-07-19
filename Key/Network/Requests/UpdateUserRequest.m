//
//  UpdateUserRequest.m
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "UpdateUserRequest.h"
#import "CollapsingFutures.h"
#import "KUser.h"

@implementation UpdateUserRequest

- (instancetype)initWithUser:(KUser *)user {
    id <KSendable>sendableUser = (id <KSendable>)user;
    NSDictionary *parameters = @{kUserAlias : [super toDictionary:sendableUser]};
    return [super initWithHttpMethod:POST endpoint:kUserEndpoint parameters:[super base64EncodedDictionary:parameters]];
}

+ (TOCFuture *)makeRequestWithUser:(KUser *)user {
    UpdateUserRequest *request = [[UpdateUserRequest alloc] initWithUser:user];
    TOCFutureSource *resultSource = [TOCFutureSource new];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        //TODO: how do we want to set status?
        [resultSource trySetResult:responseObject];
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error){
        [resultSource trySetFailure:error];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}

@end
