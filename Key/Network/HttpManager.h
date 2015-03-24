//
//  HttpManager.h
//  Key
//
//  Created by Brendan Farmer on 3/11/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSendable.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>

#define kHTTPRequestQueue   @"httpRequestQueue"
#define kHTTPResponseQueue  @"httpResponseQueue"

@interface HttpManager : NSObject

@property (nonatomic, readonly) AFHTTPRequestOperationManager *httpOperationManager;

+ (instancetype)sharedManager;

- (void)put:(id <KSendable>)object;
- (void)post:(id <KSendable>)object;
//- (void)get: (NSDictionary *)parameters;
- (void)batchPut:(NSString *)remoteAlias objects:(NSArray *)objects;
- (void)getObjectsWithRemoteAlias:(NSString *)remoteAlias parameters:(NSDictionary *)parameters;
- (void)enqueueSendableObject:(id<KSendable>)object;
- (void)enqueueGetWithRemoteAlias:(NSString *)remoteAlias parameters:(NSDictionary *)parameters;
- (NSDictionary *)base64DecodedDictionary:(NSDictionary *)dictionary;

@end
