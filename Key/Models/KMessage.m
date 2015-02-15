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

- (instancetype)initFrom:(NSString *)authorId threadId:(NSString *)threadId body:(NSString *)body {
    self = [super initWithUniqueId:nil];
    
    if (self) {
        _authorId = authorId;
        _threadId = threadId;
        _body     = body;
    }
    return self;
}

- (void)createAndSend {
    self.sendStatus = KMessageUnsentStatus;
    [self save];
    [self remoteCreate];
}

- (NSDictionary *)toDictionary {
    return @{@"outgoingMessages" : [self outgoingMessagesArray]};
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

@end
