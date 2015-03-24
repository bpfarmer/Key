//
//  KYapDatabaseObject.m
//  Key
//
//  Created by Brendan Farmer on 1/26/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KYapDatabaseObject.h"
#import "KStorageManager.h"

#define kCoderUniqueId @"uniqueId"

@implementation KYapDatabaseObject

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithUniqueId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderUniqueId]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.uniqueId forKey:kCoderUniqueId];
}

- (id)init{
    if (self = [super init])
    {
        _uniqueId = [[NSUUID UUID] UUIDString];
    }
    return self;
}

- (instancetype)initWithUniqueId:(NSString *)aUniqueId{
    if (self = [super init]) {
        _uniqueId = aUniqueId;
    }
    return self;
}

- (void)saveWithTransaction:(YapDatabaseReadWriteTransaction *)transaction{
    [transaction setObject:self forKey:self.uniqueId inCollection:[[self class] collection]];
    NSLog(@"ATTEMPTING TO SAVE WITH ID: %@", self.uniqueId);
}

- (void)save{
    [[KStorageManager sharedManager].dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [self saveWithTransaction:transaction];
    }];
}

- (void)removeWithTransaction:(YapDatabaseReadWriteTransaction *)transaction{
    [transaction removeObjectForKey:self.uniqueId inCollection:[[self class] collection]];
}


- (void)remove{
    [[KStorageManager sharedManager].dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [self removeWithTransaction:transaction];
        //[[transaction ext:@"relationships"] flush];
    }];
}

#pragma mark Class Methods

+ (NSString *)collection{
    return NSStringFromClass([self class]);
}

- (NSString *)collection {
    return [[self class] collection];
}

+ (instancetype) fetchObjectWithUniqueId:(NSString *)uniqueId transaction:(YapDatabaseReadTransaction *)transaction {
    return [transaction objectForKey:uniqueId inCollection:[self collection]];
}

+ (instancetype) fetchObjectWithUniqueId:(NSString *)uniqueId{
    __block id object;
    
    [[KStorageManager sharedManager].dbConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        object = [transaction objectForKey:uniqueId inCollection:[self collection]];
    }];
    
    return object;
}

@end