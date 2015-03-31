//
//  PushTokenRequest.h
//  Key
//
//  Created by Brendan Farmer on 3/31/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HttpRequest.h"
#import "PushTokenRequest.h"

@class TOCFuture;

@interface SendPushTokenRequest : HttpRequest

- (instancetype)initWithDeviceToken:(NSData *)deviceToken uniqueId:(NSString *)uniqueId;
+ (TOCFuture *)makeRequestWithDeviceToken:(NSData *)deviceToken uniqueId:(NSString *)uniqueId;

@end
