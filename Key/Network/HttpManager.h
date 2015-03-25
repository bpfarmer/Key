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

typedef enum {
    PUT, GET, POST, DELETE
}httpMethods;

@class HttpRequest;

@interface HttpManager : NSObject

@property (nonatomic, readonly) AFHTTPRequestOperationManager *httpOperationManager;

+ (instancetype)sharedManager;

- (void)put:(HttpRequest *)request
    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)post:(HttpRequest *)request
     success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
     failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)get:(HttpRequest *)request
     success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
     failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)enqueueRequest:(HttpRequest *)request;

@end
