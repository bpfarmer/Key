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

+ (TOCFuture *)makeRequestWithRemoteDeviceId:(NSString *)remoteDeviceId;


@end
