//
//  UpdateUserRequest.h
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HttpRequest.h"
#import "UserRequest.h"

@class TOCFuture;
@class KUser;

@interface UpdateUserRequest : HttpRequest

- (instancetype)initWithUser:(KUser *)user;
+ (TOCFuture *)makeRequestWithUser:(KUser *)user;

@end
