//
//  KStorageManager.m
//  Key
//
//  Created by Brendan Farmer on 1/26/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KStorageManager.h"
#import "KAccountManager.h"
#import <SSKeychain/SSKeychain.h>
#import "NSData+Base64.h"
#import "KUser.h"
#import "KMessage.h"
#import "Util.h"
#import "CollapsingFutures.h"

NSString *const KUIDatabaseConnectionDidUpdateNotification = @"KUIDatabaseConnectionDidUpdateNotification";
//TODO: Note that these are a single queue right now
NSString *const kDatabaseWriteQueue = @"dbWriteQueue";
NSString *const kDatabaseReadQueue  = @"dbWriteQueue";

@interface KStorageManager ()

@end

@implementation KStorageManager

+ (instancetype)sharedManager {
    static KStorageManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)setDatabaseWithName:(NSString *)databaseName {
    NSString *databasePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    self.database = [FMDatabase databaseWithPath:[NSString stringWithFormat:@"%@/%@", databasePath, databaseName]];
}

- (void)addTablesToDatabase {
    if(self.database) {
    }
}

- (void)queryUpdate:(KDatabaseUpdateBlock)databaseBlock {
    if(self.database && self.database.open) {
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:self.database.databasePath];
        [queue inDatabase:^(FMDatabase *db) {
            databaseBlock(db);
        }];
    }
}

- (FMResultSet *)querySelect:(KDatabaseSelectBlock)databaseBlock {
    __block FMResultSet *resultSet;
    if(self.database && self.database.open) {
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:self.database.databasePath];
        [queue inDatabase:^(FMDatabase *db) {
            resultSet = databaseBlock(db);
        }];
    }
    return resultSet;
}

- (NSData *)databasePassword {
    NSString *keychainDBPassKey = [NSString stringWithFormat:@"%@_%@", keychainDBPassAccount, [KAccountManager sharedManager].user.username];
    NSString *dbPassword = [SSKeychain passwordForService:keychainService account:keychainDBPassKey];
    
    if (!dbPassword) {
        dbPassword = [[Util generateRandomData:32] base64EncodedString];
        [SSKeychain setPassword:dbPassword forService:keychainService account:keychainDBPassKey];
    }
    return [dbPassword dataUsingEncoding:NSUTF8StringEncoding];
}

@end
