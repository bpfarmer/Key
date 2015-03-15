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
#import "KThread.h"
#import "KStorageManager.h"
#import "KAccountManager.h"
#import "KUser.h"
#import "Util.h"

#define kStatusUnsent @"UNSENT"
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
        _sendStatus = kStatusUnsent;
    }
    return self;
}

- (void)sendToRecipients {
}

- (NSString *)placeholderUniqueId {
    NSString *uniqueId = [NSString stringWithFormat:@"%@_%f_%@", [[KAccountManager sharedManager] uniqueId],
                          [[NSDate date] timeIntervalSince1970],
                          [Util insecureRandomString:10]];
    return uniqueId;
}

@end
