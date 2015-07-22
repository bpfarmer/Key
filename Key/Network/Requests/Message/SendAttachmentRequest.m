//
//  SendAttachmentRequest.m
//  Key
//
//  Created by Brendan Farmer on 7/21/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "SendAttachmentRequest.h"
#import "CollapsingFutures.h"

@implementation SendAttachmentRequest

- (instancetype)initWithAttachment:(Attachment *)attachment {
    NSDictionary *parameters = @{kAttachmentAlias : [super toDictionary:(id <KSendable>)attachment]};
    NSLog(@"REQUEST WITH PARAMETERS: %@", parameters);
    return [super initWithHttpMethod:PUT endpoint:kAttachmentEndpoint parameters:[super base64EncodedDictionary:parameters]];
}

+ (TOCFuture *)makeRequestWithAttachment:(Attachment *)attachment {
    NSLog(@"SHOULD BE MAKING REQUEST TO SEND ATTACHMENT.");
    TOCFutureSource *resultSource = [TOCFutureSource new];
    SendAttachmentRequest *request = [[SendAttachmentRequest alloc] initWithAttachment:attachment];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        NSLog(@"RESPONSE OBJECT FOR ATTACHMENT: %@", responseObject);
        [resultSource trySetResult:@YES];
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error){
        NSLog(@"REQUEST FAILED: %@", error);
        [resultSource trySetFailure:error];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}


@end
