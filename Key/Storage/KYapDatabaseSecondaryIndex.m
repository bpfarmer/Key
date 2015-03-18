//
//  KYapDatabaseSecondaryIndex.m
//  Key
//
//  Created by Brendan Farmer on 2/12/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KYapDatabaseSecondaryIndex.h"
#import "KStorageManager.h"
#import "KUser.h"
#import "KMessage.h"

@implementation KYapDatabaseSecondaryIndex

+ (BOOL)registerUsernameIndex {
    YapDatabaseSecondaryIndexSetup *setup = [[YapDatabaseSecondaryIndexSetup alloc] init];
    [setup addColumn:@"username" withType:YapDatabaseSecondaryIndexTypeText];
    YapDatabaseSecondaryIndexWithObjectBlock block = ^(NSMutableDictionary *dict, NSString *collection, NSString *key, id object){
        
        if ([object isKindOfClass:[KUser class]])
        {
            KUser *user = (KUser *)object;
            if(user.username)
                [dict setObject:user.username forKey:@"username"];
        }
    };
    
    YapDatabaseSecondaryIndexHandler *handler = [YapDatabaseSecondaryIndexHandler withObjectBlock:block];
    YapDatabaseSecondaryIndex *secondaryIndex = [[YapDatabaseSecondaryIndex alloc] initWithSetup:setup handler:handler];
    return [[KStorageManager sharedManager].database registerExtension:secondaryIndex withName:KUsernameSQLiteIndex];
}

+ (BOOL)registerMessageSentIndex {
    YapDatabaseSecondaryIndexSetup *setup = [[YapDatabaseSecondaryIndexSetup alloc] init];
    [setup addColumn:@"status" withType:YapDatabaseSecondaryIndexTypeText];
    YapDatabaseSecondaryIndexWithObjectBlock block = ^(NSMutableDictionary *dict, NSString *collection, NSString *key, id object){
        
        if ([object isKindOfClass:[KMessage class]])
        {
            KMessage *message = (KMessage *)object;
            if(message.status)
                [dict setObject:message.status forKey:@"status"];
        }
    };
    
    YapDatabaseSecondaryIndexHandler *handler = [YapDatabaseSecondaryIndexHandler withObjectBlock:block];
    YapDatabaseSecondaryIndex *secondaryIndex = [[YapDatabaseSecondaryIndex alloc] initWithSetup:setup handler:handler];
    return [[KStorageManager sharedManager].database registerExtension:secondaryIndex withName:KMessageStatusSQLiteIndex];
}

@end
