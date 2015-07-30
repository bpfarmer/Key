//
//  QRReadRequest.h
//  Key
//
//  Created by Brendan Farmer on 7/27/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HttpRequest.h"

@class TOCFuture;

@interface QRReadRequest : HttpRequest

+ (TOCFuture *)makeRequest;

@end
