//
//  GetMessagesRequest.m
//  Key
//
//  Created by Brendan Farmer on 3/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "GetMessagesRequest.h"
#import "CollapsingFutures.h"
#import "FreeKeyResponseHandler.h"
#import "KAccountManager.h"
#import "KUser.h"
#import "FreeKeySessionManager.h"
#import "PreKeyExchange.h"
#import "KStorageManager.h"
#import "FreeKey.h"
#import "KDevice.h"

@implementation GetMessagesRequest

- (instancetype)initWithCurrentUserId:(NSString *)currentUserId {
    NSDictionary *parameters = @{kMessageCurrentUserId : currentUserId};
    return [super initWithHttpMethod:GET endpoint:kFeedEndpoint parameters:parameters];
}

+ (TOCFuture *)makeRequestWithCurrentUserId:(NSString *)currentUserId {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    KUser *user = [KUser findById:currentUserId];
    GetMessagesRequest *request = [[GetMessagesRequest alloc] initWithCurrentUserId:user.currentDevice.deviceId];
    NSLog(@"SHOULD BE RETRIEVING FEED");
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        NSLog(@"RESPONSE OBJECT: %@", responseObject);
        [request receiveMessages:[request base64DecodedDictionary:responseObject]];
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error){
        NSLog(@"ERROR: %@", error);
        [resultSource trySetFailure:error];
    };
    [request makeRequestWithSuccess:success failure:failure];
    return resultSource.future;
}

- (void)receiveMessages:(NSDictionary *)messages {
    KUser *localUser = [KAccountManager sharedManager].user;
    if([messages[kPreKeyExchangeRemoteAlias] count] > 0) {
        if([messages[kPreKeyExchangeRemoteAlias] isKindOfClass:[NSDictionary class]]) {
            PreKeyExchange *preKeyExchange = [FreeKeyResponseHandler createPreKeyExchangeFromRemoteDictionary:messages[kPreKeyExchangeRemoteAlias]];
            KUser *remoteUser = [KUser findById:preKeyExchange.senderId];
            if(remoteUser) {
                [[FreeKeySessionManager sharedManager] processNewKeyExchange:preKeyExchange localUser:localUser remoteUser:remoteUser];
            }else {
                TOCFuture *futureUser = [KUser asyncRetrieveWithUniqueId:preKeyExchange.senderId];
                [futureUser thenDo:^(KUser *remoteUser) {
                    [[FreeKeySessionManager sharedManager] processNewKeyExchange:preKeyExchange localUser:localUser remoteUser:remoteUser];
                }];
            }
        }else {
            for(NSDictionary *msg in messages[kPreKeyExchangeRemoteAlias]) {
                PreKeyExchange *preKeyExchange = [FreeKeyResponseHandler createPreKeyExchangeFromRemoteDictionary:msg];
                KUser *remoteUser = [KUser findById:preKeyExchange.senderId];
                if(remoteUser) {
                    [[FreeKeySessionManager sharedManager] processNewKeyExchange:preKeyExchange localUser:localUser remoteUser:remoteUser];
                }else {
                    TOCFuture *futureUser = [KUser asyncRetrieveWithUniqueId:preKeyExchange.senderId];
                    [futureUser thenDo:^(KUser *remoteUser) {
                        [[FreeKeySessionManager sharedManager] processNewKeyExchange:preKeyExchange localUser:localUser remoteUser:remoteUser];
                    }];
                }
            }
        }
    }
    if([messages[kEncryptedMessageRemoteAlias] count] > 0) {
        NSLog(@"HANDLING MESSAGE");
        if([messages[kEncryptedMessageRemoteAlias] isKindOfClass:[NSDictionary class]]) {
            EncryptedMessage *message = [FreeKeyResponseHandler createEncryptedMessageFromRemoteDictionary:messages[kEncryptedMessageRemoteAlias]];
            [FreeKey decryptAndSaveEncryptedMessage:message];
        }else {
            for(NSDictionary *msg in messages[kEncryptedMessageRemoteAlias]) {
                EncryptedMessage *encryptedMessage = [FreeKeyResponseHandler createEncryptedMessageFromRemoteDictionary:msg];
                [FreeKey decryptAndSaveEncryptedMessage:encryptedMessage];
            }
        }
    }
    if([messages[kAttachmentAlias] count] > 0) {
        NSLog(@"HANDLING ATTACHMENTS");
        if([messages[kAttachmentAlias] isKindOfClass:[NSDictionary class]]) {
            Attachment *attachment = [FreeKeyResponseHandler createAttachmentFromRemoteDictionary:messages[kAttachmentAlias]];
            [FreeKey decryptAndSaveAttachment:attachment];
        }else {
            for(NSDictionary *attach in messages[kAttachmentAlias]) {
                Attachment *attachment = [FreeKeyResponseHandler createAttachmentFromRemoteDictionary:attach];
                [FreeKey decryptAndSaveAttachment:attachment];
            }
        }
    }
}

@end
