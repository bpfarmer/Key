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

#define KThreadRemoteEndpoint @"http://127.0.0.1:9393/user.json"
#define KThreadRemoteAlias @"thread"
#define KThreadRemoteCreateNotification @"KThreadRemoteCreateNotification"
#define KThreadRemoteUpdateNotification @"KThreadRemoteUpdateNotification"

@implementation KThread

- (NSArray *)yapDatabaseRelationshipEdges {
    NSArray *edges = nil;
    return edges;
}

- (instancetype)initFromRemote:(NSDictionary *)threadDictionary {
    self = [super initWithUniqueId:threadDictionary[@"uniqueId"]];
    return self;
}

- (instancetype)initWithUsers:(NSArray *)users {
    NSMutableArray *userIds = [[NSMutableArray alloc] init];
    [users enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        KUser *user = (KUser *)obj;
        [userIds addObject:user.uniqueId];
    }];
    NSArray *sortedUserIds = [userIds sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return obj1 > obj2;
    }];
    self = [super initWithUniqueId:[sortedUserIds componentsJoinedByString:@"_"]];
    if (self) {
        _userIds = sortedUserIds;
        NSMutableArray *usernames = [[NSMutableArray alloc] init];
        [users enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            KUser *user = (KUser *)obj;
            [usernames addObject:user.username];
        }];
        _name = [usernames componentsJoinedByString:@", "];
    }
    return self;
}



- (instancetype)initWithUniqueId:(NSString *)uniqueId
                         userIds:(NSArray *)userIds
                            name:(NSString *)name
                   latestMessage:(KMessage *)latestMessage
                   lastMessageAt:(NSDate *)lastMessageAt
                      archivedAt:(NSDate *)archivedAt
                            read:(BOOL)read{
    self = [super initWithUniqueId:uniqueId];
    if (self) {
        _name = name;
        _userIds            = userIds;
        _latestMessage      = latestMessage;
        _lastMessageAt      = lastMessageAt;
        _archivedAt         = archivedAt;
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
                          userIds:userIds
                             name:nil
                    latestMessage:nil
                    lastMessageAt:nil
                       archivedAt:nil
                             read:NO];
}

- (NSString *)displayName {
    NSMutableArray *usernames = [[NSMutableArray alloc] initWithArray:[self.name componentsSeparatedByString:@", "]];
    [usernames removeObject:[KAccountManager sharedManager].user.username];
    return [usernames componentsJoinedByString:@", "];
}

- (NSDictionary *)toDictionary {
    return @{@"uniqueId" : self.uniqueId,
             @"userIds"  : self.userIds};
}

+ (NSString *)remoteEndpoint {
    return KThreadRemoteEndpoint;
}

+ (NSString *)remoteAlias {
    return KThreadRemoteAlias;
}

+ (NSString *)remoteCreateNotification {
    return KThreadRemoteCreateNotification;
}

- (void)processLatestMessage:(KMessage *)message {
    KUser *currentUser = [KAccountManager sharedManager].user;
    if(![message.authorId isEqualToString:currentUser.uniqueId]) {
        self.read = NO;
    }else {
        self.read = YES;
    }
    
    if(self.latestMessage) {
        NSComparisonResult dateComparison = [message.createdAt compare:self.latestMessage.createdAt];
        switch (dateComparison) {
            case NSOrderedDescending : self.latestMessage = message; break;
            default : break;
        }
    }else {
        self.latestMessage = message;
    }
    
    [self save];
}

- (NSArray *)recipientIds {
    KUser *localUser = [KAccountManager sharedManager].user;
    NSMutableArray *recipientIds = [NSMutableArray arrayWithArray:self.userIds];
    [recipientIds removeObject:localUser.uniqueId];
    return recipientIds;
}

@end