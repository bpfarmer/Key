//
//  GetUsersRequest.h
//  Key
//
//  Created by Brendan Farmer on 3/30/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserRequest.h"
#import "HttpRequest.h"

@class TOCFuture;

@interface GetUsersRequest : HttpRequest

- (instancetype)initWithParameters:(NSDictionary *)parameters;
+ (TOCFuture *)makeRequestWithParameters:(NSDictionary *)parameters;

@end
