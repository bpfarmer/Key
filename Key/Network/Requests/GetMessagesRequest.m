//
//  GetMessagesRequest.m
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "GetMessagesRequest.h"
#import "CollapsingFutures.h"
#import "KAccountManager.h"
#import "KUser.h"
#import "EncryptedMessage.h"
#import "Attachment.h"
#import "PreKeyExchange.h"
#import "KStorageManager.h"
#import "FreeKey.h"

@implementation GetMessagesRequest

- (instancetype)initWithCurrentUserId:(NSString *)currentUserId {
    NSDictionary *parameters = @{kMessageCurrentUserId : currentUserId};
    return [super initWithHttpMethod:GET endpoint:kFeedEndpoint parameters:parameters];
}

+ (TOCFuture *)makeRequestWithCurrentUserId:(NSString *)currentUserId {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    KUser *user = [KUser findById:currentUserId];
    GetMessagesRequest *request = [[GetMessagesRequest alloc] initWithCurrentUserId:user.currentDeviceId];
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        NSDictionary *messages = [request base64DecodedDictionary:responseObject];
        for(NSDictionary *msg in messages[kEncryptedMessageRemoteAlias]) {
            EncryptedMessage *encryptedMessage = [[EncryptedMessage alloc] init];
            [encryptedMessage setValuesForKeysWithDictionary:msg];
            [FreeKey decryptAndSaveEncryptedMessage:encryptedMessage];
        }
        for(NSDictionary *attach in messages[kAttachmentAlias]) {
            Attachment *attachment = [[Attachment alloc] init];
            [attachment setValuesForKeysWithDictionary:attach];
            [FreeKey decryptAndSaveAttachment:attachment];
        }
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error){
        [resultSource trySetFailure:error];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}


@end
