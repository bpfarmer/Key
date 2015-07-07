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
#import "Util.h"
#import "CollapsingFutures.h"

NSString *const KUIDatabaseConnectionDidUpdateNotification = @"KUIDatabaseConnectionDidUpdateNotification";
NSString *const kDatabaseWriteQueue = @"dbWriteQueue";
NSString *const kDatabaseReadQueue  = @"dbReadQueue";

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

- (TOCFuture *)queryUpdate:(NSString *)sql parameters:(NSDictionary *)parameters {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    
    if(self.database && self.database.open) {
        NSString *databasePath = self.database.databasePath;
        dispatch_queue_t queue = dispatch_queue_create([kDatabaseWriteQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
        dispatch_async(queue, ^{
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:databasePath];
            [queue inDatabase:^(FMDatabase *db) {
                [db executeUpdate:sql withParameterDictionary:parameters];
                [resultSource trySetResult:@"SUCCESS"];
            }];
        });
    }
    
    return resultSource.future;
}

- (TOCFuture *)querySelect:(NSString *)sql parameters:(NSDictionary *)parameters {
    TOCFutureSource *resultSource = [TOCFutureSource new];
    
    if(self.database && self.database.open) {
        NSString *databasePath = self.database.databasePath;
        dispatch_queue_t queue = dispatch_queue_create([kDatabaseReadQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
        dispatch_async(queue, ^{
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:databasePath];
            [queue inDatabase:^(FMDatabase *db) {
                FMResultSet *resultSet = [db executeQuery:sql withParameterDictionary:parameters];
                NSMutableArray *objects = [[NSMutableArray alloc] init];
                if(resultSet) {
                    while(resultSet.next) {
                        [objects addObject:[[KDatabaseObject alloc] initWithResultSetRow:resultSet.resultDictionary]];
                    }
                    [resultSource trySetResult:objects];
                }else {
                    [resultSource trySetFailure:nil];
                }
            }];
        });
    }
    return resultSource.future;
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
