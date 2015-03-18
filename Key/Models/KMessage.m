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

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                        authorId:(NSString *)authorId
                        threadId:(NSString *)threadId
                            body:(NSString *)body
                          status:(NSString *)status
                       createdAt:(NSDate *)createdAt{
    self = [super initWithUniqueId:uniqueId];
    
    if(self) {
        _authorId = authorId;
        _threadId = threadId;
        _body     = body;
        _status   = status;
        _createdAt = createdAt;
    }
    return self;
}

- (instancetype)initWithAuthorId:(NSString *)authorId threadId:(NSString *)threadId body:(NSString *)body {
    self = [super init];
    
    if(self) {
        _authorId = authorId;
        _threadId = threadId;
        _body     = body;
        [self setUniqueId:[self generateUniqueId]];
    }
    
    return self;
}

- (NSString *)generateUniqueId {
    NSString *uniqueId = [NSString stringWithFormat:@"%@_%f_%@", self.authorId,
                          [[NSDate date] timeIntervalSince1970],
                          [Util insecureRandomString:10]];
    
    return uniqueId;
}

@end
