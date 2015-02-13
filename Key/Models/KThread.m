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
            //[self setNameFromUsers];
        }else {
            self = thread;
        }
    }
    
    return self;
}

- (void)setNameFromUsers {
    NSArray *fullNames = [KUser fullNamesForUserIds:[self userIds]];
    [self setName:[fullNames componentsJoinedByString:@", "]];
}

@end