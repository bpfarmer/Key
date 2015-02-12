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
        [self setUniqueId:[userIds componentsJoinedByString:@"_"]];
        [self setNameFromUsers];
    }
    
    return self;
}

- (void)setNameFromUsers {
    NSArray *fullNames = [KUser fullNamesForUserIds:[self userIds]];
    [self setName:[fullNames componentsJoinedByString:@", "]];
}

@end