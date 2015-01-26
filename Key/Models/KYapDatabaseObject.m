//
//  KYapDatabaseObject.m
//  Key
//
//  Created by Brendan Farmer on 1/26/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KYapDatabaseObject.h"
#import "KStorageManager.h"

@implementation KYapDatabaseObject

- (id)init{
    if (self = [super init])
    {
        _publicId = [[NSUUID UUID] UUIDString];
    }
    return self;
}

- (instancetype)initWithpublicId:(NSString *)apublicId{
    if (self = [super init]) {
        _publicId = apublicId;
    }
    return self;
}

- (void)saveWithTransaction:(YapDatabaseReadWriteTransaction *)transaction{
    [transaction setObject:self forKey:self.publicId inCollection:[[self class] collection]];
}

- (void)save{
    [[KStorageManager sharedManager].dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [self saveWithTransaction:transaction];
    }];
}

- (void)removeWithTransaction:(YapDatabaseReadWriteTransaction *)transaction{
    [transaction removeObjectForKey:self.publicId inCollection:[[self class] collection]];
}


- (void)remove{
    [[KStorageManager sharedManager].dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [self removeWithTransaction:transaction];
        [[transaction ext:@"relationships"] flush];
    }];
}


#pragma mark Class Methods

+ (NSString *)collection{
    return NSStringFromClass([self class]);
}

+ (instancetype) fetchObjectWithpublicId:(NSString *)publicId transaction:(YapDatabaseReadTransaction *)transaction {
    return [transaction objectForKey:publicId inCollection:[self collection]];
}

+ (instancetype) fetchObjectWithpublicId:(NSString *)publicId{
    __block id object;
    
    [[KStorageManager sharedManager].dbConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        object = [transaction objectForKey:publicId inCollection:[self collection]];
    }];
    
    return object;
}

@end