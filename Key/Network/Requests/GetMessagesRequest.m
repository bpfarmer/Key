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
        NSLog(@"FEED RESPONSE OBJECT: %@", responseObject);
        NSDictionary *messages = [request base64DecodedDictionary:responseObject];
        NSMutableArray *userIds = [NSMutableArray new];
        NSMutableArray *encryptedMessages = [NSMutableArray new];
        
        for(NSDictionary *msg in messages[kEncryptedMessageRemoteAlias]) {
            EncryptedMessage *encryptedMessage = [EncryptedMessage new];
            [encryptedMessage setValuesForKeysWithDictionary:msg];
            [encryptedMessages addObject:encryptedMessage];
            [userIds addObject:[encryptedMessage.senderId componentsSeparatedByString:@"_"].firstObject];
        }
        
        NSMutableArray *attachments = [NSMutableArray new];
        for(NSDictionary *attach in messages[kAttachmentAlias]) {
            Attachment *attachment = [Attachment new];
            [attachment setValuesForKeysWithDictionary:attach];
            [attachments addObject:attachment];
        }
        
        TOCFuture *futureUsers = [KUser asyncFindByIds:userIds];
        [futureUsers thenDo:^(id value) {
            for(EncryptedMessage *em in encryptedMessages) {
                [FreeKey decryptAndSaveEncryptedMessage:em];
            }
            [FreeKey decryptAndSaveAttachments:[attachments copy]];
        }];
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error){
        [resultSource trySetFailure:error];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}


@end
