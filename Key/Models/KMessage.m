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
#import "NSDate+TimeAgo.h"

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
        _readAt     = [NSDate date];
    }
    
    return self;
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
    return [[KThread alloc] initWithUserIds:[self.threadId componentsSeparatedByString:@"_"]];
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

- (NSString *)displayDate {
    return self.createdAt.formattedAsTimeAgo;
}

+ (NSString *)generateUniqueId {
    return [self generateUniqueIdWithClass];
}

@end
