//
//  KThread.m
//  Key
//
//  Created by Brendan Farmer on 2/5/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KThread.h"
#import "Util.h"
#import "KUser.h"
#import "KStorageManager.h"
#import "FreeKey.h"
#import "KAccountManager.h"
#import "KMessage.h"

@implementation KThread

- (instancetype)initWithUsers:(NSArray *)users {
    NSMutableArray *userIds = [[NSMutableArray alloc] init];
    NSMutableArray *usernames = [[NSMutableArray alloc] init];
    for(KUser *user in users) {
        [userIds addObject:user.uniqueId];
        [usernames addObject:user.username];
    }
    KThread *oldThread = [KThread findByDictionary:@{@"name" : [usernames componentsJoinedByString:@", "]}];
    if(oldThread) {
        self = oldThread;
        return self;
    }
    
    self = [super init];
    if (self) {
        _userIds = [userIds componentsJoinedByString:@"_"];
        _name = [usernames componentsJoinedByString:@", "];
    }
    return self;
}

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                         userIds:(NSString *)userIds
                            name:(NSString *)name
                 latestMessageId:(NSString *)latestMessageId
                            read:(BOOL)read {
    
    self = [super initWithUniqueId:uniqueId];
    if (self) {
        _name = name;
        _userIds            = userIds;
        _latestMessageId    = latestMessageId;
        _read               = read;
    }
    return self;
}

- (instancetype)initWithRemoteId:(NSString *)threadId {
    NSArray *userIds = [threadId componentsSeparatedByString:@"_"];
    [userIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        KUser *user = [KUser findById:obj];
        if(!user) {
            [KUser asyncRetrieveWithUniqueId:obj];
        }
    }];
    return [self initWithUniqueId:threadId
                          userIds:[userIds componentsJoinedByString:@"_"]
                             name:nil
                  latestMessageId:nil
                             read:NO];
}

- (void)processLatestMessage:(KMessage *)message {
    KUser *currentUser = [KAccountManager sharedManager].user;
    if(![message.authorId isEqualToString:currentUser.uniqueId]) {
        self.read = NO;
    }else {
        self.read = YES;
    }
    
    NSLog(@"PROCESSING LATEST MESSAGE");
    if(self.lastMessageAt) {
        if([self isMostRecentMessage:message]) {
            self.lastMessageAt = message.createdAt;
            self.latestMessageId = message.uniqueId;
            [self save];
            NSLog(@"SHOULD BE HERE");
        }else {
            return;
        }
    }else {
        NSLog(@"WHY IS THIS HERE");
        self.latestMessageId = message.uniqueId;
        self.lastMessageAt   = message.createdAt;
        [self save];
    }
}

- (BOOL)isMostRecentMessage:(KMessage *)newMessage {
    NSComparisonResult dateComparison = [newMessage.createdAt compare:self.lastMessageAt];
    switch (dateComparison) {
        case NSOrderedDescending : return YES; break;
        default : return NO; break;
    }
}

- (BOOL)isMoreRecentThan:(KThread *)thread {
    NSComparisonResult dateComparison = [self.lastMessageAt compare:thread.lastMessageAt];
    switch (dateComparison) {
        case NSOrderedDescending : return YES; break;
        default : return NO; break;
    }
}

- (NSString *)displayName {
    NSMutableArray *names = [[NSMutableArray alloc] initWithArray:[self.name componentsSeparatedByString:@", "]];
    [names removeObject:[KAccountManager sharedManager].user.username];
    return [names componentsJoinedByString:@", "];
}

- (NSArray *)recipientIds {
    KUser *localUser = [KAccountManager sharedManager].user;
    NSMutableArray *recipientIds = [NSMutableArray arrayWithArray:[self.userIds componentsSeparatedByString:@"_"]];
    [recipientIds removeObject:localUser.uniqueId];
    return [recipientIds copy];
}

+ (NSArray *)inbox {
    NSString *inboxSQL = [NSString stringWithFormat:@"select * from %@ order by last_message_at desc", [KThread tableName]];
    
    return [[KStorageManager sharedManager] querySelectObjects:^NSArray *(FMDatabase *database) {
        FMResultSet *result =  [database executeQuery:inboxSQL];
        NSMutableArray *threads = [[NSMutableArray alloc] init];
        while(result.next) [threads addObject:[[KThread alloc] initWithResultSetRow:result.resultDictionary]];
        [result close];
        return [threads copy];
    }];
}

- (NSArray *)messages {
    NSString *messagesInThreadSQL = [NSString stringWithFormat:@"select * from %@ where thread_id = :thread_id", [KMessage tableName]];
    NSDictionary *parameters = @{@"thread_id" : self.uniqueId};
    
    return [[KStorageManager sharedManager] querySelectObjects:^NSArray *(FMDatabase *database) {
        FMResultSet *result =  [database executeQuery:messagesInThreadSQL withParameterDictionary:parameters];
        NSMutableArray *messages = [[NSMutableArray alloc] init];
        while(result.next) [messages addObject:[[KMessage alloc] initWithResultSetRow:result.resultDictionary]];
        [result close];
        return [messages copy];
    }];
}

- (KMessage *)latestMessage {
    return [KMessage findById:self.latestMessageId];
}

- (BOOL)saved {
    return ([KThread findById:self.uniqueId] != nil);
}
@end