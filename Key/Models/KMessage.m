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

@implementation KMessage

- (NSArray *)yapDatabaseRelationshipEdges {
    NSArray *edges = nil;
    return edges;
}

- (instancetype)initFrom:(NSString *)authorId threadId:(NSString *)threadId body:(NSString *)body {
    self = [super initWithUniqueId:[[self class] placeholderUniqueId]];
    
    if (self) {
        _authorId = authorId;
        _threadId = threadId;
        _body     = body;
    }
    return self;
}

- (void)sendMessages {
    KThread *thread = [[KStorageManager sharedManager] objectForKey:[self threadId] inCollection:[KThread collection]];
    NSArray *keyPairs = [KUser fullNamesForUserIds:[thread userIds]];
    
    NSMutableArray *outgoingMessages = nil;
    for (KKeyPair *keyPair in keyPairs) {
        [outgoingMessages addObject: [self encryptForKeyPair:keyPair]];
    }
    
    [self sendMessageCrypts:outgoingMessages];
}

- (KOutgoingMessage *)encryptForKeyPair:(KKeyPair *)keyPair {
    return [[KOutgoingMessage alloc] initWithMessage:self keyPair:keyPair];
}

- (void)sendMessageCrypts:(NSArray *)messageCrypts {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:kMessageSendEndpoint parameters:@{@"messages" : messageCrypts} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON FROM SEND MESSAGE CHECK: %@", responseObject);
        if([responseObject[@"status"]  isEqual:@"FAILURE"]) {
        }else {
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

+ (NSString *)placeholderUniqueId {
    NSTimeInterval today = [[NSDate date] timeIntervalSince1970];
    NSString *uniqueId = [NSString stringWithFormat:@"%@_%f_%@", [[KAccountManager currentUser] uniqueId], today, [Util insecureRandomString:10]];
    return uniqueId;
}

@end
