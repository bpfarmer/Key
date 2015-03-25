//
//  HTTPRequest.m
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HttpRequest.h"
@implementation HttpRequest

- (instancetype)initWithHttpMethod:(httpMethods)httpMethod endpoint:(NSString *)endpoint parameters:(NSDictionary *)parameters {
    self = [super init];
    if(self) {
        _httpMethod = httpMethod;
        _endpoint   = endpoint;
        _parameters = parameters;
    }
    
    return self;
}

- (void)makeRequestWithSuccess:(void (^)(AFHTTPRequestOperation *, id))success
                       failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
    
    switch(self.httpMethod) {
        case PUT:
            [[HttpManager sharedManager] put:self success:success failure:failure];
            break;
        case GET:
            
            break;
        case POST:
            
            break;
        case DELETE:
            
            break;
        default:
            break;
    }
}

@end
