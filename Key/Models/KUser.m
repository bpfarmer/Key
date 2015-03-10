//
//  KUser.m
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KUser.h"
#import "KMessage.h"
#import "KStorageManager.h"
#import "KAccountManager.h"
#import "KThread.h"
#import "KYapDatabaseSecondaryIndex.h"

#define KUserRemoteEndpoint @"http://127.0.0.1:9393/user.json"
#define KUserRemoteAlias @"user"
#define KUserRemoteCreateNotification @"KUserRemoteCreateNotification"
#define KUserRemoteUpdateNotification @"KUserRemoteUpdateNotification"

@implementation KUser

#pragma mark - Initializers

- (instancetype)initWithUsername:(NSString *)username {
    self = [super initWithUniqueId:nil];
    
    if (self) {
        _username = username;
    }

    return self;
}

- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password {
    self = [self initWithUsername:username];
    if (self) {
        _plainPassword = password;
        [[self class ] registerCreateNotificationObserver];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self remoteCreate];
        });
    }
    return self;
}

- (instancetype)initWithRemoteUsername:(NSString *)username {
    self = [[self class] fetchWithUsername:username];
    
    if (!self) {
        self = [self initWithUsername:username];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //[self getRemoteUser];
        });
    }
    return self;
}

- (void)startAccountManager {
    if(self.uniqueId) {
        if(self.plainPassword)
            self.plainPassword = nil;
        [[KAccountManager sharedManager] initWithUniqueId:self.uniqueId];
        [self save];
    }
}

#pragma mark - User Registration
+ (void)finishUserRegistration:(NSNotification *)notification {
    if([notification.object isKindOfClass:[self class]]) {
        KUser *user = (KUser *)[notification object];
        if([user.remoteStatus isEqualToString:KRemoteCreateSuccessStatus]) {
            [self removeCreateNotificationObserver];
            NSString *plainPassword = user.plainPassword;
            [user startAccountManager];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[KStorageManager sharedManager] setupDatabase];
                [user generatePassword:plainPassword];
                [user remoteUpdate];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:KUserRegisterUsernameStatusNotification object:user];
        });
    }
}

- (void)generatePassword:(NSString *)plainPassword {
    /*NSDictionary *encryptedPasswordDictionary = [[[KCryptor alloc] init] encryptOneWay: plainPassword];
    self.plainPassword = nil;
    [self setPasswordCrypt:encryptedPasswordDictionary[@"encrypted"]];
    [self setPasswordSalt:encryptedPasswordDictionary[@"salt"]];*/
}

+ (NSString *)remoteEndpoint {
    return KUserRemoteEndpoint;
}

+ (NSString *)remoteAlias {
    return KUserRemoteAlias;
}

+ (NSString *)remoteCreateNotification {
    return KUserRemoteCreateNotification;
}

+ (NSString *)remoteUpdateNotification {
    return KUserRemoteUpdateNotification;
}

# pragma mark - Notification Methods
+ (void)registerCreateNotificationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(finishUserRegistration:)
                                                 name:[self remoteCreateNotification]
                                               object:nil];
}

+ (void)removeCreateNotificationObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:[self remoteCreateNotification] object:nil];
}

#pragma mark - Batch Query Methods

+ (NSArray *)keyPairsForUserIds:(NSArray *)userIds {
    NSMutableArray *keyPairs = [[NSMutableArray alloc] init];
    
    [[[KStorageManager sharedManager] dbConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateObjectsForKeys:userIds inCollection:[self collection] unorderedUsingBlock:^(NSUInteger keyIndex, id object, BOOL *stop) {
            [keyPairs addObject:[object activeKeyPair]];
        }];
    }];
    
    return keyPairs;
}

+ (NSArray *)fullNamesForUserIds:(NSArray *)userIds {
    NSMutableArray *fullNames = [[NSMutableArray alloc] init];
    
    [[[KStorageManager sharedManager] dbConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateRowsForKeys:userIds inCollection:[self collection] unorderedUsingBlock:^(NSUInteger keyIndex, id object, id metadata, BOOL *stop) {
            [fullNames addObject:[object fullName]];
        }];
    }];
    return fullNames;
}

#pragma mark - Query Methods
+ (KUser *)fetchWithUsername:(NSString *)username {
    __block KUser *user = [[KUser alloc] init];
    
    [[[KStorageManager sharedManager] dbConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        YapDatabaseQuery *query = [YapDatabaseQuery queryWithFormat:[NSString stringWithFormat:@"WHERE username = %@", username]];
        [[transaction ext:KUsernameSQLiteIndex] enumerateKeysMatchingQuery:query usingBlock:^(NSString *collection, NSString *key, BOOL *stop) {
            user = (KUser *)[[KStorageManager sharedManager] objectForKey:key inCollection:[self collection]];
        }];
    }];
    return user;
}

#pragma mark - User Custom Attributes

- (NSString *)fullName {
    return [self username];
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
    if(self.uniqueId) [userDictionary addEntriesFromDictionary:@{@"uniqueId" : self.uniqueId}];
    if(self.username) [userDictionary addEntriesFromDictionary:@{@"username" : self.username}];
    if(self.passwordCrypt) [userDictionary addEntriesFromDictionary:@{@"passwordCrypt" : self.passwordCrypt}];
    return userDictionary;
}

#pragma mark - YapDatabase Methods

- (NSArray *)yapDatabaseRelationshipEdges {
    NSArray *edges = nil;
    return edges;
}

@end
