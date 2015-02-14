//
//  KYapDatabaseObject.m
//  Key
//
//  Created by Brendan Farmer on 1/26/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KYapDatabaseObject.h"
#import "KStorageManager.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>

@implementation KYapDatabaseObject

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

#pragma mark Remote Server Methods

- (void)remoteCreate {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:[[self class] remoteEndpoint] parameters:@{[[self class] remoteAlias] : [self toDictionary]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if([responseObject[@"status"]  isEqual:@"SUCCESS"]) {
            [self setUniqueId:responseObject[[[self class] remoteAlias]][@"uniqueId"]];
            [self setRemoteStatus:KRemoteCreateSuccessStatus];
        }else {
            [self setRemoteStatus:KRemoteCreateFailureStatus];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:[[self class] remoteCreateNotification] object:self];
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self setRemoteStatus:KRemoteCreateNetworkFailureStatus];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:[[self class] remoteCreateNotification] object:self];
        });
    }];
}

- (void)remoteUpdate {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:[[self class] remoteEndpoint] parameters:@{[[self class] remoteAlias] : [self toDictionary]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if([responseObject[@"status"] isEqual:@"SUCCESS"]) {
            [self setRemoteStatus:KRemoteUpdateSuccessStatus];
            [self saveFromRemoteUpdateResponse:responseObject[[[self class] remoteAlias]]];
        } else {
            [self setRemoteStatus:KRemoteUpdateFailureStatus];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:[[self class] remoteUpdateNotification] object:self];
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self setRemoteStatus:KRemoteUpdateNetworkFailureStatus];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:[[self class] remoteUpdateNotification] object:self];
        });
    }];
}

- (void)remoteDistribute {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:[[self class] remoteEndpoint] parameters:@{[[self class] remoteAlias] : [self toDistributeDictionary]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if([responseObject[@"status"] isEqual:@"SUCCESS"]) {
            [self setRemoteStatus:KRemoteDistributeSuccessStatus];
            [self saveFromRemoteUpdateResponse:responseObject[[[self class] remoteAlias]]];
        } else {
            [self setRemoteStatus:KRemoteDistributeFailureStatus];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:[[self class] remoteDistributeNotification] object:self];
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self setRemoteStatus:KRemoteDistributeNetworkFailureStatus];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:[[self class] remoteDistributeNotification] object:self];
        });
    }];

}

- (void)saveFromRemoteUpdateResponse:(NSDictionary *)responseObject {
    [self save];
}

- (NSDictionary *)toDictionary {
    return nil;
}

- (NSDictionary *)toDistributeDictionary {
    return nil;
}

+ (NSString *)remoteEndpoint {
    return nil;
}

+ (NSString *)remoteAlias {
    return nil;
}

+ (NSString *)remoteCreateNotification {
    return nil;
}

+ (NSString *)remoteUpdateNotification {
    return nil;
}

+ (NSString *)remoteDistributeNotification {
    return nil;
}

#pragma mark Class Methods

+ (NSString *)collection{
    return NSStringFromClass([self class]);
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