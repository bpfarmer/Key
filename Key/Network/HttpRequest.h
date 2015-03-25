//
//  HTTPRequest.h
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpManager.h"

@class AFHTTPRequestOperation;

@interface HttpRequest : NSObject

@property (nonatomic) httpMethods httpMethod;
@property (nonatomic) NSString *endpoint;
@property (nonatomic) NSDictionary *parameters;

- (instancetype)initWithHttpMethod:(httpMethods)httpMethod endpoint:(NSString *)endpoint parameters:(NSDictionary *)parameters;
- (void)makeRequestWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                       failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@end