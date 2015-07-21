//
//  LoginRequest.m
//  Key
//
//  Created by Brendan Farmer on 7/18/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "LoginRequest.h"
#import "CollapsingFutures.h"
#import "KUser.h"
#import "NSData+Base64.h"
#import "NSString+Base64.h"

@implementation LoginRequest

- (instancetype)initWithParameters:(NSDictionary *)parameters {
    self = [super initWithHttpMethod:POST endpoint:kUserLoginEndpoint parameters:[super base64EncodedDictionary:parameters]];
    return self;
}

- (instancetype)initWithSaltParameters:(NSDictionary *)parameters {
    self = [super initWithHttpMethod:GET endpoint:kUserLoginSaltEndpoint parameters:parameters];
    return self;
}

+ (TOCFuture *)makeSaltRequestWithParameters:(NSDictionary *)parameters {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    NSLog(@"SENDING PARAMS: %@", parameters);
    LoginRequest *request = [[LoginRequest alloc] initWithSaltParameters:(NSDictionary *)parameters];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        NSLog(@"RESPONSE OBJECT: %@", responseObject);
        if([responseObject[@"status"] isEqualToString:@"SUCCESS"]) {
            [resultSource trySetResult:[((NSString *)responseObject[kUserPasswordSalt]) base64DecodedData]];
        }else {
            [resultSource trySetFailure:nil];
        }
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error){
        NSLog(@"ERROR: %@", error);
        [resultSource trySetFailure:error];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}

+ (TOCFuture *)makeRequestWithParameters:(NSDictionary *)parameters {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    LoginRequest *request = [[LoginRequest alloc] initWithParameters:parameters];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        NSLog(@"RESPONSE OBJECT: %@", responseObject);
        if([responseObject[@"status"] isEqualToString:@"SUCCESS"]) {
            [resultSource trySetResult:[self createUserFromDictionary:[request base64DecodedDictionary:responseObject]]];
        }else {
            [resultSource trySetFailure:nil];
        }
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error){
        NSLog(@"ERROR: %@", error);
        [resultSource trySetFailure:error];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}

+ (KUser *)createUserFromDictionary:(NSDictionary *)dictionary {
    NSDictionary *userDictionary = dictionary[kUserAlias];
    if(userDictionary) {
        KUser *user = [[KUser alloc] initWithUniqueId:userDictionary[@"uniqueId"]
                                      username:userDictionary[@"username"]
                                     publicKey:userDictionary[@"publicKey"]];
        [user setHasLocalPreKey:NO];
        [user save];
        return user;
    }
    return nil;
}


@end
