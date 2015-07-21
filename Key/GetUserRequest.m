//
//  GetUserRequest.m
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "GetUserRequest.h"
#import "CollapsingFutures.h"
#import "KUser.h"
#import "FreeKey.h"
#import "FreeKeyNetworkManager.h"
#import "KStorageManager.h"
#import "PreKeyExchange.h"
#import "PreKey.h"

@implementation GetUserRequest

- (instancetype)initWithParameters:(NSDictionary *)parameters {
    self = [super initWithHttpMethod:GET endpoint:kUserEndpoint parameters:parameters];
    return self;
}

+ (TOCFuture *)makeRequestWithParameters:(NSDictionary *)parameters {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    GetUserRequest *request = [[GetUserRequest alloc] initWithParameters:parameters];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        if(responseObject[kUsersAlias]) {
            NSArray *usersResponseArray = (NSArray *) responseObject[kUsersAlias];
            NSMutableArray *usersArray  = [[NSMutableArray alloc] init];
            if(usersResponseArray.count > 0) {
                for (NSDictionary *user in usersResponseArray) {
                    [usersArray addObject:[request createUserFromDictionary:[request base64DecodedDictionary:user]]];
                }
                [resultSource trySetResult:usersArray];
            }
        }else {
            KUser *remoteUser = [request createUserFromDictionary:[request base64DecodedDictionary:responseObject]];
            if(remoteUser.uniqueId) [resultSource trySetResult:remoteUser];
        }
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error){
        NSLog(@"ERROR: %@", error);
        [resultSource trySetFailure:error];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}

- (KUser *)createUserFromDictionary:(NSDictionary *)dictionary {
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
