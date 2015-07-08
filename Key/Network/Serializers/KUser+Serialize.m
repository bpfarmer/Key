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
#import <objc/runtime.h>

@implementation KUser(Serialize)

+ (void)createTable {
    NSString *createTableSQL = [NSString stringWithFormat:@"create table %@ (unique_id text primary key not null, username text, password_crypt blob, password_salt blob, identity_key blob, public_key blob);", [self tableName]];
    
    [[KStorageManager sharedManager] queryUpdate:^(FMDatabase *database) {
        [database executeUpdate:createTableSQL];
    }];
}

@end
