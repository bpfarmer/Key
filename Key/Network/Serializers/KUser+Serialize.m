//
//  KUser+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 3/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KUser+Serialize.h"
#import "IdentityKey.h"
#import "KStorageManager.h"
#import "CollapsingFutures.h"

@implementation KUser(Serialize)

+ (void)createTable {
    NSString *createTableSQL = [NSString stringWithFormat:@"create table %@ (unique_id text primary key not null, username text, password_crypt blob, password_salt blob, identity_key blob, public_key blob);", [self tableName]];
    [[KStorageManager sharedManager] queryUpdate:createTableSQL parameters:nil];
}

- (void)save {
    if(self.uniqueId) {
        NSString *insertOrReplaceSQL = [NSString stringWithFormat:@"insert or replace into %@ (unique_id, username) values(:unique_id, :username)", [self.class tableName]];
        
        NSDictionary *userDictionary = [NSDictionary dictionaryWithObjectsAndKeys:self.uniqueId, @"unique_id", self.username, @"username", nil];
        [[KStorageManager sharedManager] queryUpdate:insertOrReplaceSQL parameters:userDictionary];
    }
}

+ (TOCFuture *)all {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    NSString *findAllSQL = [NSString stringWithFormat:@"select * from %@", [self.class tableName]];
    [resultSource trySetResult:[[KStorageManager sharedManager] querySelect:findAllSQL parameters:nil]];
    return resultSource.future;
}

- (void)remove {
    if(self.uniqueId) {
        NSString *deleteSQL = [NSString stringWithFormat:@"delete from %@ where unique_id = :unique_id", [self.class tableName]];
        NSDictionary *userDictionary = [NSDictionary dictionaryWithObjectsAndKeys:self.uniqueId, @"unique_id", nil];
        [[KStorageManager sharedManager] queryUpdate:deleteSQL parameters:userDictionary];
    }
}

@end
