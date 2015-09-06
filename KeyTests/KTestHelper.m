//
//  KTestHelper.m
//  Key
//
//  Created by Brendan Farmer on 9/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KTestHelper.h"
#import "KAccountManager.h"
#import "KStorageManager.h"
#import "KStorageSchema.h"
#import "KUser.h"

@implementation KTestHelper

+ (void)setup {
    NSString *testDB = @"testDB";
    KStorageManager *manager = [KStorageManager sharedManager];
    [manager setDatabaseWithName:testDB];
    [KStorageSchema createTables];
    KUser *currentUser = [[KUser alloc] initWithUniqueId:@"1"];
    currentUser.username = @"testUser";
    [currentUser save];
    [[KAccountManager sharedManager] setUser:currentUser];
    [self createFakeUsers];
}

+ (void)tearDown {
    [KStorageSchema dropTables];
    [[KStorageManager sharedManager] resignDatabase];
}

+ (void)createFakeUsers {
    KUser *user2 = [[KUser alloc] initWithUniqueId:@"2" username:@"2" publicKey:nil];
    [user2 save];
    KUser *user3 = [[KUser alloc] initWithUniqueId:@"3" username:@"3" publicKey:nil];
    [user3 save];
    KUser *user4 = [[KUser alloc] initWithUniqueId:@"4" username:@"4" publicKey:nil];
    [user4 save];
    KUser *user5 = [[KUser alloc] initWithUniqueId:@"5" username:@"5" publicKey:nil];
    [user5 save];
}

@end
