//
//  SendPreKeysRequest.h
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HttpRequest.h"
#import "PreKeyRequest.h"

@class TOCFuture;

@interface SendPreKeysRequest : HttpRequest

- (instancetype)initWithPreKeys:(NSArray *)preKeys;
+ (TOCFuture *)makeRequestWithPreKeys:(NSArray *)preKeys;

@end
