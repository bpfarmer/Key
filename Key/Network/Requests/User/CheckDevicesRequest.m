//
//  CheckDevicesRequest.m
//  Key
//
//  Created by Brendan Farmer on 7/20/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "CheckDevicesRequest.h"
#import "CollapsingFutures.h"
#import "KUser.h"
#import "NSData+Base64.h"
#import "NSString+Base64.h"
#import "KDevice.h"

@implementation CheckDevicesRequest

- (instancetype)initWithParameters:(NSDictionary *)parameters {
    self = [super initWithHttpMethod:GET endpoint:kUserCheckDevicesEndpoint parameters:[super base64EncodedDictionary:parameters]];
    return self;
}

+ (TOCFuture *)makeRequestWithUserIds:(NSArray *)userIds {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    CheckDevicesRequest *request = [[CheckDevicesRequest alloc] initWithParameters:@{@"users" : userIds}];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        if([responseObject[@"status"] isEqualToString:@"SUCCESS"]) {
            for(NSDictionary *userDevices in responseObject[@"users"]) {
                [userDevices enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    for(NSString *deviceId in obj) [KDevice addDeviceForUserId:key deviceId:deviceId];
                }];
            }
            [resultSource trySetResult:@YES];
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

@end
