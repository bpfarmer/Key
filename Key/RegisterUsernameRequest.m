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

- (instancetype)initWithUser:(KUser *)user password:(NSData *)password salt:(NSData *)salt{
    NSDictionary *parameters = @{kUserAlias : @{kUserUsername : user.username, kUserPasswordCrypt : password, kUserPasswordSalt : salt}};
    NSLog(@"REGISTRATION PARAMS: %@", [super base64EncodedDictionary:parameters]);
    return [super initWithHttpMethod:PUT endpoint:kUserEndpoint parameters:[super base64EncodedDictionary:parameters]];
}

+ (TOCFuture *)makeRequestWithUser:(KUser *)user password:(NSData *)password salt:(NSData *)salt{
    TOCFutureSource *resultSource = [TOCFutureSource new];
    RegisterUsernameRequest *request = [[RegisterUsernameRequest alloc] initWithUser:user password:password salt:salt];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        [user setUniqueId:responseObject[kUserAlias][kUserUniqueId]];
        if(user.uniqueId) [resultSource trySetResult:user];
        else [resultSource trySetFailure:nil];
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error){
        [resultSource trySetFailure:error];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}

@end
