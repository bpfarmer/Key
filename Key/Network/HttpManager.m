//
//  HttpManager.m
//  Key
//
//  Created by Brendan Farmer on 3/11/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HttpManager.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>

#define kRemoteEndpoint @"http://127.0.0.1:9393"

@implementation HttpManager

+ (instancetype)sharedManager {
    static HttpManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (NSString *)endpointForObject:(id <KSendable>)object {
    return [NSString stringWithFormat:@"%@/%@.json", kRemoteEndpoint, [self remoteAlias:object]];
}

- (NSString *)remoteAlias:(id <KSendable>)object {
    NSString *lowercaseClass = [NSStringFromClass([object class]) lowercaseString];
    return [lowercaseClass substringFromIndex:1];
}

- (void)put:(id <KSendable>)object {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager PUT:[self endpointForObject:object]
      parameters:@{[self remoteAlias:object] : [self toDictionary:object]}
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if([responseObject[@"status"]  isEqual:@"SUCCESS"]) {
            [object setUniqueId:responseObject[[self remoteAlias:object]][@"uniqueId"]];
            [object setRemoteStatus:kRemotePutSuccessStatus];
        }else {
            [object setRemoteStatus:kRemotePutFailureStatus];
        }
        [self fireNotification:kRemotePutNotification object:object];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [object setRemoteStatus:kRemotePutNetworkFailureStatus];
        [self fireNotification:kRemotePutNotification object:object];
    }];
}

- (void)post:(id <KSendable>)object {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:[self endpointForObject:object]
       parameters:@{[self remoteAlias:object] : [self toDictionary:object]}
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              
        if([responseObject[@"status"] isEqual:@"SUCCESS"]) {
            [object setRemoteStatus:kRemotePostSuccessStatus];
        } else {
            [object setRemoteStatus:kRemotePostFailureStatus];
        }
        [self fireNotification:kRemotePostNotification object:object];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [object setRemoteStatus:kRemotePostNetworkFailureStatus];
        [self fireNotification:kRemotePostNotification object:object];
    }];
}

- (void)get:(NSDictionary *)parameters {

}

- (void)fireNotification:(NSString *)notfication object:(id <KSendable>)object {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kRemotePutNotification object:object];
    });
}

- (NSDictionary *)toDictionary:(id <KSendable>)object {
    NSObject *objectForDictionary = (NSObject *)object;
    return [objectForDictionary dictionaryWithValuesForKeys:[object keysToSend]];
}

+ (NSString *)remoteEndpoint {
    return nil;
}

+ (NSString *)remoteAlias {
    return nil;
}

+ (NSString *)remoteCreateNotification {
    return nil;
}

+ (NSString *)remoteUpdateNotification {
    return nil;
}

@end
