//
//  SendMessageRequest.h
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HttpRequest.h"
#import "KSendable.h"
#import "MessageRequest.h"

@class TOCFuture;

@interface SendMessageRequest : HttpRequest

- (instancetype)initWithSendableMessage:(id <KSendable>)message;
+ (TOCFuture *)makeRequestWithSendableMessage:(id <KSendable>)message;

@end
