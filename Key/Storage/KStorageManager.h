//
//  KStorageManager.h
//  Key
//
//  Created by Brendan Farmer on 1/26/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YapDatabase/YapDatabase.h>

extern NSString *const KUIDatabaseConnectionDidUpdateNotification;

static NSString *keychainService          = @"KKeyChainService";
static NSString *keychainDBPassAccount    = @"KDatabasePass";

@interface KStorageManager : NSObject

@property (nonatomic, readonly) YapDatabaseConnection *dbConnection;


+ (instancetype)sharedManager;
- (void)releaseDatabaseAndConnection;
- (void)refreshDatabaseAndConnection;

- (void)setupDatabase;
- (YapDatabase *)database;
- (YapDatabaseConnection *)newDatabaseConnection;
- (NSString *)dbPath;

- (NSUInteger)numberOfKeysInCollection:(NSString *)collection;
- (void)setObject:(id)object forKey:(NSString*)key inCollection:(NSString*)collection;
- (void)removeObjectForKey:(NSString*)string inCollection:(NSString *)collection;
- (BOOL)boolForKey:(NSString*)key inCollection:(NSString*)collection;
- (id)objectForKey:(NSString*)key inCollection:(NSString *)collection;
- (NSDictionary *)dictionaryForKey:(NSString*)key inCollection:(NSString *)collection;
- (NSString *)stringForKey:(NSString*)key inCollection:(NSString*)collection;
- (NSData *)dataForKey:(NSString*)key inCollection:(NSString*)collection;

- (void)purgeCollection:(NSString*)collection;
- (void)wipe;
@end