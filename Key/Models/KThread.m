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
    
    if(self.latestMessageId) {
        KMessage *latestMessage = [KMessage findById:self.latestMessageId];
        NSComparisonResult dateComparison = [message.createdAt compare:latestMessage.createdAt];
        switch (dateComparison) {
            case NSOrderedDescending : latestMessage = message; break;
            default : break;
        }
    }else {
        self.latestMessageId = message.uniqueId;
    }
    
    [self save];
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
    return recipientIds;
}

- (NSArray *)messages {
    NSString *messagesInThreadSQL = [NSString stringWithFormat:@"select * from %@ where thread_id = :thread_id", [KMessage tableName]];
    NSDictionary *parameters = @{@"thread_id" : self.uniqueId};
    
    FMResultSet *resultSet = [[KStorageManager sharedManager] querySelect:^FMResultSet *(FMDatabase *database) {
        return [database executeQuery:messagesInThreadSQL withParameterDictionary:parameters];
    }];
    
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    while(resultSet.next) [messages addObject:[[KMessage alloc] initWithResultSetRow:resultSet.resultDictionary]];
    [resultSet close];
    return messages;
}

- (BOOL)saved {
    return ([KThread findById:self.uniqueId] != nil);
}
@end