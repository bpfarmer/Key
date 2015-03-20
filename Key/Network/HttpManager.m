//
//  HttpManager.m
//  Key
//
//  Created by Brendan Farmer on 3/11/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HttpManager.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "FreeKey.h"
#import "NSData+Base64.h"
#import "EncryptedMessage.h"
#import "KAccountManager.h"

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

- (NSString *)endpointForObject:(NSString *)objectAlias {
    return [NSString stringWithFormat:@"%@/%@.json", kRemoteEndpoint, objectAlias];
}

- (NSString *)remoteAlias:(id <KSendable>)object {
    return [[object class] remoteAlias];
}

- (void)put:(id <KSendable>)object {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager PUT:[self endpointForObject:[self remoteAlias:object]]
      parameters:@{[self remoteAlias:object] : [self toDictionary:object]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if([responseObject[@"status"] isEqual:@"SUCCESS"]) {
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
    [manager POST:[self endpointForObject:[self remoteAlias:object]]
       parameters:@{[self remoteAlias:object] : [self toDictionary:object]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
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

- (void)getObjectsWithRemoteAlias:(NSString *)remoteAlias parameters:(NSDictionary *)parameters {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:[self endpointForObject:remoteAlias] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"RESPONSE OBJECT: %@", responseObject);
         if([responseObject[@"status"] isEqual:@"SUCCESS"]) {
             if([remoteAlias isEqualToString:kFeedRemoteAlias]) {
                 [[FreeKey sharedManager] receiveRemoteFeed:responseObject withLocalUser:[KAccountManager sharedManager].user];
             }else {
                 [[FreeKey sharedManager] receiveRemoteObject:responseObject ofType:remoteAlias];
             }
         }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // TODO: try again
    }];
}

- (void)batchPut:(NSString *)remoteAlias objects:(NSArray *)objects {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager PUT:[self endpointForObject:remoteAlias] parameters:@{remoteAlias : objects} success:^(AFHTTPRequestOperation *operation, id responseObject) {
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (void)fireNotification:(NSString *)notification object:(id <KSendable>)object {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notification object:object];
    });
}

- (NSDictionary *)toDictionary:(id <KSendable>)object {
    NSMutableDictionary *requestDictionary = [[NSMutableDictionary alloc] init];
    NSObject *objectForDictionary = (NSObject *)object;
    [[[object class] remoteKeys] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSObject *property = [objectForDictionary dictionaryWithValuesForKeys:@[obj]][obj];
        if([property isKindOfClass:[NSData class]]) {
            NSData *dataProperty = (NSData *)property;
            NSString *encodedString = [dataProperty base64EncodedString];
            [requestDictionary addEntriesFromDictionary:@{obj : encodedString}];
        }else {
            [requestDictionary addEntriesFromDictionary:@{obj : property}];
        }
    }];
    return requestDictionary;
}

@end
