//
//  CheckDevicesRequest.h
//  Key
//
//  Created by Brendan Farmer on 7/20/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HttpRequest.h"
#import "UserRequest.h"

@class TOCFuture;

@interface CheckDevicesRequest : HttpRequest

- (instancetype)initWithParameters:(NSDictionary *)parameters;
+ (TOCFuture *)makeRequestWithUserIds:(NSArray *)userIds;

@end

