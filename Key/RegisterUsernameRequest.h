//
//  RegisterUsernameRequest.h
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HttpRequest.h"

@class TOCFuture;
@class KUser;

@interface RegisterUsernameRequest : HttpRequest

- (instancetype)initWithUser:(KUser *)user;
+ (TOCFuture *)makeRequestWithUser:(KUser *)user;

@end
