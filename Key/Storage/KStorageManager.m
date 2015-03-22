//
//  KStorageManager.m
//  Key
//
//  Created by Brendan Farmer on 1/26/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KStorageManager.h"
#import "KAccountManager.h"
#import <YapDatabase/YapDatabase.h>
#import <YapDatabase/YapDatabaseRelationship.h>
#import <SSKeychain/SSKeychain.h>
#import "NSData+Base64.h"
#import "KYapDatabaseView.h"
#import "KYapDatabaseSecondaryIndex.h"
#import "KUser.h"
#import "Util.h"

NSString *const KUIDatabaseConnectionDidUpdateNotification = @"KUIDatabaseConnectionDidUpdateNotification";

@interface KStorageManager ()

@property (nonatomic, retain) NSMutableDictionary *databases;

@end

@implementation KStorageManager

+ (instancetype)sharedManager {
    static KStorageManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
        //[sharedMyManager protectDatabaseFile];
    });
    return sharedMyManager;
}

- (instancetype)init {
    self = [super init];
    
    // TODO: THROWAWAY METHOD
    if(![KAccountManager sharedManager].user) {
        KUser *testUser = [[KUser alloc] initWithUsername:@"testUser"];
        [[KAccountManager sharedManager] setUser:testUser];
    }
    
    [self refreshDatabaseAndConnection];
    
    return self;
}

- (YapDatabase *)database {
    return [self.databases objectForKey:[KAccountManager sharedManager].user.username];
}

- (void)refreshDatabaseAndConnection {
    YapDatabaseOptions *options = [[YapDatabaseOptions alloc] init];
    options.corruptAction = YapDatabaseCorruptAction_Fail;
    options.passphraseBlock = ^{
        return [self databasePassword];
    };
    
    NSString *username = [KAccountManager sharedManager].user.username;
    if(!_databases) {
        _databases = [[NSMutableDictionary alloc] init];
    }
    
    if(![_databases objectForKey:username]) {
        YapDatabase *newDatabase = [[YapDatabase alloc] initWithPath:[self dbPath]
                                                    objectSerializer:NULL
                                                  objectDeserializer:NULL
                                                  metadataSerializer:NULL
                                                metadataDeserializer:NULL
                                                     objectSanitizer:NULL
                                                   metadataSanitizer:NULL
                                                             options:options];
        [_databases setObject:newDatabase forKey:username];
    }
    
    _dbConnection = self.newDatabaseConnection;
}

- (YapDatabase *)currentDatabase {
    return [self.databases objectForKey:[KAccountManager sharedManager].user.username];
}

- (void)setupDatabase {
    [KYapDatabaseView registerThreadDatabaseView];
    [KYapDatabaseView registerMessageDatabaseView];
    [KYapDatabaseView registerContactDatabaseView];
    [KYapDatabaseSecondaryIndex registerUsernameIndex];
}

/**
 *  Protects the preference and logs file with disk encryption and prevents them to leak to iCloud.
 */

- (void)protectDatabaseFile{
    
    NSDictionary *attrs = @{NSFileProtectionKey: NSFileProtectionCompleteUntilFirstUserAuthentication};
    NSError *error;
    
    
    [NSFileManager.defaultManager setAttributes:attrs ofItemAtPath:[self dbPath] error:&error];
    [[NSURL fileURLWithPath:[self dbPath]] setResourceValue:@YES
                                                     forKey:NSURLIsExcludedFromBackupKey
                                                      error:&error];
    
    /*
    if (error) {
        DDLogError(@"Error while removing log files from backup: %@", error.description);
        UIAlertView *alert  = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"WARNING", @"")
                                                        message:NSLocalizedString(@"DISABLING_BACKUP_FAILED", @"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }*/
}

- (YapDatabaseConnection *)newDatabaseConnection {
    return [self currentDatabase].newConnection;
}

- (BOOL)userSetPassword {
    return FALSE;
}

- (BOOL)dbExists {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self dbPath]];
}

- (NSString *)dbPath {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSURL *fileURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *path = [fileURL path];
    return [path stringByAppendingFormat:@"/%@", [KAccountManager sharedManager].user.username];
}

- (NSString *)databasePassword {
    NSString *keychainDBPassKey = [NSString stringWithFormat:@"%@_%@", keychainDBPassAccount, [KAccountManager sharedManager].user.username];
    NSString *dbPassword = [SSKeychain passwordForService:keychainService account:keychainDBPassKey];
    
    if (!dbPassword) {
        dbPassword = [[Util generateRandomData:32] base64EncodedString];
        [SSKeychain setPassword:dbPassword forService:keychainService account:keychainDBPassKey];
    }
    return dbPassword;
}

#pragma mark convenience methods

- (void)purgeCollection:(NSString*)collection {
    [self.dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeAllObjectsInCollection:collection];
    }];
}

- (NSUInteger)numberOfKeysInCollection:(NSString *)collection {
    __block NSUInteger count;
    
    [self.dbConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        count = [transaction numberOfKeysInCollection:(NSString *)collection];
    }];
    return count;
}

- (void)setObject:(id)object forKey:(NSString*)key inCollection:(NSString*)collection {
    [self.dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:object forKey:key inCollection:collection];
    }];
}

- (void)removeObjectForKey:(NSString*)string inCollection:(NSString *)collection{
    [self.dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeObjectForKey:string inCollection:collection];
    }];
}

- (id)objectForKey:(NSString*)key inCollection:(NSString *)collection {
    __block NSString *object;
    
    [self.dbConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        object = [transaction objectForKey:key inCollection:collection];
    }];
    
    return object;
}

- (NSDictionary*)dictionaryForKey:(NSString*)key inCollection:(NSString *)collection {
    __block NSDictionary *object;
    
    [self.dbConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        object = [transaction objectForKey:key inCollection:collection];
    }];
    
    return object;
}

- (NSString*)stringForKey:(NSString*)key inCollection:(NSString*)collection {
    NSString *string = [self objectForKey:key inCollection:collection];
    
    return string;
}

- (BOOL)boolForKey:(NSString*)key inCollection:(NSString*)collection {
    NSNumber *boolNum = [self objectForKey:key inCollection:collection];
    
    return [boolNum boolValue];
}

- (NSData*)dataForKey:(NSString*)key inCollection:(NSString*)collection {
    NSData *data = [self objectForKey:key inCollection:collection];
    return data;
}

- (void)wipe{
    [_databases setObject:nil forKey:[KAccountManager sharedManager].user.username];
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:[self dbPath] error:&error];
    
    if (error) {
        //DDLogError(@"Failed to delete database: %@", error.description);
    }
    
    [self setupDatabase];
}

@end
