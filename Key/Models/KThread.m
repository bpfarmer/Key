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
        _userIds = userIds;
        [self setUniqueIdFromUsers];
        [self setNameFromUsers];
    }
    
    return self;
}

- (NSArray *)users {
    id (^mapBlock)(id obj) = (id) ^(id obj){
        [[KStorageManager sharedManager] objectForKey: inCollection:<#(NSString *)#>
    };
    return nil;
}

- (void)setNameFromUsers {
    NSMutableArray *fullNames = [self mapUsers:^(id user){
        return [user fullName];
    }];
    [self setName:[fullNames componentsJoinedByString:@", "]];
}

- (void)setUniqueIdFromUsers {
    NSMutableArray *uniqueIds = [self mapUsers: ^(id user){
        return [user uniqueId];
    }];
    [uniqueIds sortedArrayUsingSelector:@selector(caseSensitive)];
    [self setUniqueId:[uniqueIds componentsJoinedByString:@"_"]];
}

- (NSMutableArray *)mapUsers: (id (^)(id obj))block
{
    NSMutableArray *new = [NSMutableArray array];
    for(id obj in [self users])
    {
        id newObj = block(obj);
        [new addObject: newObj ? newObj : [NSNull null]];
    }
    return new;
}

@end