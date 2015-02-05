//
//  KMessage.m
//  Key
//
//  Created by Brendan Farmer on 1/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//
#import "KMessage.h"
#import "KGroup.h"
#import "KMessageCrypt.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "KUser.h"
#import "KKeyPair.h"
#import "KThread.h"
#import "KStorageManager.h"
#import "KUser.h"

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

- (void)sendMessages {
    KThread *thread = [[KStorageManager sharedManager] objectForKey:[self threadId] inCollection:[KThread collection]];
    NSArray *keyPairs = [KUser fullNamesForUserIds:[thread userIds]];
    
    NSMutableArray *messageCrypts = nil;
    for (KKeyPair *keyPair in keyPairs) {
        [messageCrypts addObject: [self encryptForKeyPair:keyPair]];
    }
    
    [self sendMessageCrypts:messageCrypts];
}

- (KMessageCrypt *)encryptForKeyPair:(KKeyPair *)keyPair {
    return [[KMessageCrypt alloc] initWithMessage:self keyPair:keyPair];
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

@end
