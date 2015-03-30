//
//  GetMessagesRequest.h
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HttpRequest.h"
#import "MessageRequest.h"

@class TOCFuture;

@interface GetMessagesRequest : HttpRequest

- (instancetype)initWIthCurrentUserId:(NSString *)currentUserId;
+ (TOCFuture *)makeRequestWithCurrentUserId:(NSString *)currentUserId;

@end
