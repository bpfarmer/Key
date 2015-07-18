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

@implementation LoginRequest

- (instancetype)initWithParameters:(NSDictionary *)parameters {
    NSLog(@"SENDING: %@",[super base64EncodedDictionary:parameters]);
    self = [super initWithHttpMethod:POST endpoint:kUserLoginEndpoint parameters:[super base64EncodedDictionary:parameters]];
    return self;
}

+ (TOCFuture *)makeRequestWithParameters:(NSDictionary *)parameters {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    LoginRequest *request = [[LoginRequest alloc] initWithParameters:parameters];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        NSLog(@"RESPONSE OBJECT: %@", responseObject);
        if([responseObject[@"status"] isEqualToString:@"SUCCESS"]) {
            [resultSource trySetResult:[self createUserFromDictionary:(NSDictionary *)responseObject[kUserAlias]]];
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
    KUser *user;
    
    if(userDictionary) {
        user = [[KUser alloc] initWithUniqueId:userDictionary[@"uniqueId"]
                                      username:userDictionary[@"username"]
                                     publicKey:userDictionary[@"publicKey"]];
        [user setHasLocalPreKey:NO];
        [user save];
    }
    
    return user;
}


@end
