//
//  KMessage.m
//  Key
//
//  Created by Brendan Farmer on 1/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//
#import "KMessage.h"
#import "KGroup.h"
#import "KUser.h"
#import "KThread.h"
#import "KStorageManager.h"
#import "KAccountManager.h"
#import "KUser.h"
#import "Util.h"

#define kStatusUnsent @"UNSENT"

@implementation KMessage

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                        authorId:(NSString *)authorId
                        threadId:(NSString *)threadId
                            body:(NSString *)body
                          status:(NSString *)status
                       createdAt:(NSDate *)createdAt {
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
        _createdAt = [NSDate date];
        [self setUniqueId:[self generateUniqueId]];
        _read     = YES;
    }
    
    return self;
}

- (NSString *)generateUniqueId {
    NSString *uniqueId = [NSString stringWithFormat:@"%@_%u", [KMessage tableName], [self messageHash]];
    
    return uniqueId;
}

- (NSUInteger)messageHash {
    return self.authorId.hash ^ (NSUInteger) [self.createdAt timeIntervalSince1970] ^ self.body.hash;
}

- (KUser *)author {
    return [KUser findById:self.authorId];
}

- (void)save {
    [super save];
    [self.thread processLatestMessage:self];
}

- (KThread *)thread {
    return [KThread findById:self.threadId];
}

- (NSString *)text {
    return self.body;
}

- (NSDate *)date {
    return self.createdAt;
}

#pragma mark - JSQMessageData Protocol
- (NSString *)senderId {
    return self.authorId;
}

- (NSString *)senderDisplayName {
    return [self author].username;
}

- (BOOL)isMediaMessage {
    return NO;
}

@end
