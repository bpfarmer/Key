//
//  SendAttachmentRequest.h
//  Key
//
//  Created by Brendan Farmer on 7/21/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HttpRequest.h"
#import "MessageRequest.h"

@class TOCFuture;
@class Attachment;

@interface SendAttachmentRequest : HttpRequest

- (instancetype)initWithAttachment:(Attachment *)attachment;
+ (TOCFuture *)makeRequestWithAttachment:(Attachment *)attachment;
@end
