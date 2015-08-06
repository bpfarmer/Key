//
//  HttpManager.m
//  Key
//
//  Created by Brendan Farmer on 3/11/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HttpManager.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "NSData+Base64.h"
#import "NSString+Base64.h"
#import "EncryptedMessage.h"
#import "KAccountManager.h"
#import "HttpRequest.h"

@implementation HttpManager

- (instancetype)init {
    self = [super init];
    if(self) {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        _httpOperationManager = manager;
    }
    return self;
}

+ (instancetype)sharedManager {
    static HttpManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)put:(HttpRequest *)request
    success:(void (^)(AFHTTPRequestOperation *, id))success
    failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
    
    [self.httpOperationManager PUT:request.endpoint parameters:request.parameters success:success failure:failure];
}

- (void)post:(HttpRequest *)request
    success:(void (^)(AFHTTPRequestOperation *, id))success
    failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
    
    [self.httpOperationManager POST:request.endpoint parameters:request.parameters success:success failure:failure];
}

- (void)get:(HttpRequest *)request
     success:(void (^)(AFHTTPRequestOperation *, id))success
     failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
    
    [self.httpOperationManager GET:request.endpoint parameters:request.parameters success:success failure:failure];
}

@end
