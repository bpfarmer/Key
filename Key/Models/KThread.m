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

- (instancetype)initWithUsers:(NSArray *)userIds {
    self = [super initWithUniqueId:nil];
    if (self) {
        _userIds = [userIds sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return obj1 > obj2;
        }];
        NSString *uniqueId = [userIds componentsJoinedByString:@"_"];
        KThread *thread = [[KStorageManager sharedManager] objectForKey:uniqueId inCollection:[KThread collection]];
        if (!thread) {
            [self setUniqueId:uniqueId];
        }else {
            self = thread;
        }
    }
    return self;
}

- (NSDictionary *)toDictionary {
    return @{@"uniqueId" : self.uniqueId,
             @"userIds"  : self.userIds};
}

- (void)setNameFromUsers {
    NSArray *fullNames = [KUser fullNamesForUserIds:[self userIds]];
    [self setName:[fullNames componentsJoinedByString:@", "]];
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