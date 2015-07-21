//
//  GetKeyExchangeRequest.h
//  Key
//
//  Created by Brendan Farmer on 3/27/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HttpRequest.h"
#import "PreKeyRequest.h"

@class TOCFuture;
@class KUser;

@interface GetKeyExchangeRequest : HttpRequest

- (instancetype)initWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser;
+ (TOCFuture *)makeRequestWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser;
- (instancetype)initWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser deviceId:(NSString *)deviceId;
+ (TOCFuture *)makeRequestWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser deviceId:(NSString *)deviceId;


@end
