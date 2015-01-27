//
//  KStorageManager.m
//  Key
//
//  Created by Brendan Farmer on 1/26/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KStorageManager.h"
#import <YapDatabase/YapDatabase.h>
#import <YapDatabase/YapDatabaseRelationship.h>
#import <SSKeychain/SSKeychain.h>
#import "KCryptor.h"
#import "NSData+Base64.h"

NSString *const KUIDatabaseConnectionDidUpdateNotification = @"KUIDatabaseConnectionDidUpdateNotification";

static const NSString *const databaseName  = @"Key.sqlite";
static NSString * keychainService          = @"KKeyChainService";
static NSString * keychainDBPassAccount    = @"KDatabasePass";

@interface KStorageManager ()

@property YapDatabase *database;

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
    
    YapDatabaseOptions *options = [[YapDatabaseOptions alloc] init];
    options.corruptAction = YapDatabaseCorruptAction_Fail;
    options.passphraseBlock = ^{
        return [self databasePassword];
    };
    
    _database = [[YapDatabase alloc] initWithPath:[self dbPath]
                                 objectSerializer:NULL
                               objectDeserializer:NULL
                               metadataSerializer:NULL
                             metadataDeserializer:NULL
                                  objectSanitizer:NULL
                                metadataSanitizer:NULL
                                          options:options];
    _dbConnection = self.newDatabaseConnection;
    return self;
}

- (void)setupDatabase {
    //[TSDatabaseView registerThreadDatabaseView];
    //[TSDatabaseView registerBuddyConversationDatabaseView];
    //[TSDatabaseView registerUnreadDatabaseView];
    
    //[self.database registerExtension:[[YapDatabaseRelationship alloc] init] withName:@"TSRelationships"];
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
    return self.database.newConnection;
}

- (BOOL)userSetPassword {
    return FALSE;
}

- (BOOL)dbExists {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self dbPath]];
}

- (NSString*)dbPath {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSURL *fileURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *path = [fileURL path];
    return [path stringByAppendingFormat:@"/%@", databaseName];
}

- (NSString*)databasePassword {
    [SSKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];
    NSString *dbPassword = [SSKeychain passwordForService:keychainService account:keychainDBPassAccount];
    
    if (!dbPassword) {
        dbPassword = [[KCryptor generateSecureRandomData:30] base64EncodedString];
        [SSKeychain setPassword:dbPassword forService:keychainService account:keychainDBPassAccount];
        //DDLogError(@"Set new password from keychain ...");
    }
    
    return dbPassword;
}

#pragma mark convenience methods

- (void)purgeCollection:(NSString*)collection {
    [self.dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeAllObjectsInCollection:collection];
    }];
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
    NSData *data   = [self objectForKey:key inCollection:collection];
    return data;
}

- (void)wipe{
    self.database = nil;
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:[self dbPath] error:&error];
    
    if (error) {
        //DDLogError(@"Failed to delete database: %@", error.description);
    }
    
    [self setupDatabase];
}

@end
