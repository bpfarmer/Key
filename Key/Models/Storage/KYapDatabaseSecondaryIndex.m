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

@implementation KYapDatabaseSecondaryIndex

+ (BOOL)registerUsernameIndex {
    YapDatabaseSecondaryIndexSetup *setup = [ [YapDatabaseSecondaryIndexSetup alloc] init];
    [setup addColumn:KUsernameSQLiteIndex withType:YapDatabaseSecondaryIndexTypeReal];
    
    YapDatabaseSecondaryIndexWithObjectBlock block = ^(NSMutableDictionary *dict, NSString *collection, NSString *key, id object){
        
        if ([object isKindOfClass:[KUser class]])
        {
            KUser *user = (KUser *)object;
            
            [dict setObject:user.username forKey:KUsernameSQLiteIndex];
        }
    };
    
    YapDatabaseSecondaryIndexHandler *handler = [YapDatabaseSecondaryIndexHandler withObjectBlock:block];
    
    YapDatabaseSecondaryIndex *secondaryIndex = [[YapDatabaseSecondaryIndex alloc] initWithSetup:setup handler:handler];
    
    return [[[KStorageManager sharedManager].database registerExtension:secondaryIndex withName:@"KUsernameSQLiteIndex"];
}

@end
