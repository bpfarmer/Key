//
//  KDatabaseObject.m
//  Key
//
//  Created by Brendan Farmer on 7/6/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"

@implementation KDatabaseObject

- (NSString *)tableName {
    return [self class];
}

@end
