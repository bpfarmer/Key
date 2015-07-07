//
//  KDatabaseObject.m
//  Key
//
//  Created by Brendan Farmer on 7/6/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"
#import "KStorageManager.h"
#import <objc/runtime.h>

@implementation KDatabaseObject

+ (void)createTable {
}

+ (void)dropTable {
    NSString *dropTableSQL = [NSString stringWithFormat:@"drop table %@;", [self class]];
    [[KStorageManager sharedManager] queryUpdate:dropTableSQL parameters:nil];
}

- (void)remove {
    
}

- (void)save{
    
}

- (instancetype)initWithUniqueId:(NSString *)uniqueId {
    self = [super init];
    
    if(self) _uniqueId = uniqueId;
    
    return self;
}

- (instancetype)initWithResultSetRow:(NSDictionary *)row {
    self = [super init];
    
    if(self) _uniqueId = row[@"unique_id"];
    
    return self;
}

+ (NSString *)tableName {
    return NSStringFromClass([self class]);
}

@end
