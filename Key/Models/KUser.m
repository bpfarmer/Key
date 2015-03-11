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
#import "FreeKey.h"

#define KRemoteEndpoint @"http://127.0.0.1:9393/user.json"
#define KRemoteAlias @"user"
#define KRemoteCreateNotification @"KUserRemoteCreateNotification"
#define KRemoteUpdateNotification @"KUserRemoteUpdateNotification"

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
    }
    return self;
}

#pragma mark - User Registration
+ (void)finishUserRegistration:(NSNotification *)notification {
    if([notification.object isKindOfClass:[KUser class]]) {
        KUser *user = (KUser *)[notification object];
        [self removeCreateNotificationObserver];
        NSString *plainPassword = user.plainPassword;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[KStorageManager sharedManager] setupDatabase];
            [user generatePassword:plainPassword];
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:KUserRegisterUsernameStatusNotification object:user];
        });
    }
}

- (void)generatePassword:(NSString *)plainPassword {
    // TODO: use strong 1-way hashing for password encryption
}

# pragma mark - Notification Methods
+ (void)registerCreateNotificationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(finishUserRegistration:)
                                                 name:nil
                                               object:nil];
}

+ (void)removeCreateNotificationObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
}

#pragma mark - Batch Query Methods

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
