//
//  SendPreKeyExchangeRequest.h
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HttpRequest.h"
#import "PreKeyRequest.h"

@class TOCFuture;
@class PreKeyExchange;

@interface SendPreKeyExchangeRequest : HttpRequest

- (instancetype)initWithPreKeyExchange:(PreKeyExchange *)preKeyExchange;
+ (TOCFuture *)makeRequestWithPreKeyExchange:(PreKeyExchange *)preKeyExchange;

@end
