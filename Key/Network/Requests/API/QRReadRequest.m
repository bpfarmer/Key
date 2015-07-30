//
//  QRReadRequest.m
//  Key
//
//  Created by Brendan Farmer on 7/27/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "QRReadRequest.h"
#import "CollapsingFutures.h"

#define kQRCodeEndpoint @"qr_code.json"

@implementation QRReadRequest

- (instancetype)init {
    self = [super initWithHttpMethod:GET endpoint:kQRCodeEndpoint parameters:nil];
    return self;
}

+ (TOCFuture *)makeRequest {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    QRReadRequest *request = [self new];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        [resultSource trySetResult:@YES];
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error){
        [resultSource trySetFailure:error];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}

@end
