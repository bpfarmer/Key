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
                      archivedAt:(NSDate *)archivedAt {
    self = [super initWithUniqueId:uniqueId];
    if (self) {
        _name = name;
        _userIds       = userIds;
        _latestMessage = latestMessage;
        _lastMessageAt = lastMessageAt;
        _archivedAt    = archivedAt;
    }
    return self;
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

@end