//
//  KMessage.m
//  Key
//
//  Created by Brendan Farmer on 1/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//
#import "KMessage.h"
#import "KGroup.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "KUser.h"
#import "KKeyPair.h"
#import "KThread.h"
#import "KStorageManager.h"
#import "KAccountManager.h"
#import "KUser.h"
#import "KOutgoingMessage.h"
#import "Util.h"

//API Endpoints
#define KMessageRemoteEndpoint @"http://127.0.0.1:9393/message.json"
#define KMessageRemoteAlias @"message"
#define KMessageUnsentStatus @"KMessageUnsent"
#define KMessageSentSuccessStatus @"KMessageSentSuccess"
#define KMessageSentFailureStatus @"KMessageSentFailure"
#define KMessageSentNetworkFailureStatus @"KMessageSentNetworkFailure"
#define KMessageRemoteCreateNotification @"KMessageRemoteCreateNotification"

@implementation KMessage

- (NSArray *)yapDatabaseRelationshipEdges {
    NSArray *edges = nil;
    return edges;
}

- (instancetype)initFromAuthorId:(NSString *)authorId threadId:(NSString *)threadId body:(NSString *)body {
    self = [super initWithUniqueId:[self placeholderUniqueId]];
    
    if (self) {
        _authorId = authorId;
        _threadId = threadId;
        _body     = body;
        _sendStatus = KMessageUnsentStatus;
    }
    return self;
}

- (void)sendToRecipients {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self remoteCreate];
    });
}

- (NSDictionary *)toDictionary {
    return @{@"outgoingMessages" : [self outgoingMessagesArray],
                     @"authorId" : self.authorId,
                     @"threadId" : self.threadId};
}

- (NSArray *)outgoingMessagesArray {
    __block NSMutableArray *outgoingMessages = [[NSMutableArray alloc] init];
    KThread *thread = [[KStorageManager sharedManager] objectForKey:[self threadId] inCollection:[KThread collection]];
    [[[KStorageManager sharedManager] dbConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateObjectsForKeys:thread.userIds inCollection:[KUser collection] unorderedUsingBlock:^(NSUInteger keyIndex, id object, BOOL *stop) {
            KUser *user = (KUser *)object;
            [outgoingMessages addObject:[[[KOutgoingMessage alloc] initWithMessage:self user:user] toDictionary]];
        }];
    }];
    return outgoingMessages;
}

+ (NSString *)remoteEndpoint {
    return KMessageRemoteEndpoint;
}

+ (NSString *)remoteAlias {
    return KMessageRemoteAlias;
}

+ (NSString *)remoteCreateNotification {
    return KMessageRemoteCreateNotification;
}

- (NSString *)placeholderUniqueId {
    NSTimeInterval today = [[NSDate date] timeIntervalSince1970];
    NSString *uniqueId = [NSString stringWithFormat:@"%@_%f_%@", [[KAccountManager currentUser] uniqueId], today, [Util insecureRandomString:10]];
    return uniqueId;
}

@end
