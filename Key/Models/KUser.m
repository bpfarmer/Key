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
#import "IdentityKey.h"
#import <25519/Curve25519.h>
#import "HttpManager.h"
#import <CommonCrypto/CommonCrypto.h>
#import "Util.h"
#import <SSKeychain/SSKeychain.h>
#import "NSData+Base64.h"
#import "NSString+Base64.h"

#define kRemoteCreateNotification @"KUserRemoteCreateNotification"
#define kRemoteUpdateNotification @"KUserRemoteUpdateNotification"

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
        _passwordCrypt = [password dataUsingEncoding:NSUTF8StringEncoding];
    }
    return self;
}

#pragma mark - User Registration
- (void)registerUsername {
    [[HttpManager sharedManager] put:self];
}

- (void)finishUserRegistration {
    IdentityKey *identityKey = [[IdentityKey alloc] initWithKeyPair:[Curve25519 generateKeyPair] userId:self.uniqueId];
    [self setIdentityKey:identityKey];
    [self save];
    [[HttpManager sharedManager] post:self];
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
+ (KUser *)fetchObjectWithUsername:(NSString *)username {
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
    if(self.passwordCrypt) [userDictionary addEntriesFromDictionary:@{@"password" : self.passwordCrypt}];
    return userDictionary;
}

#pragma mark - YapDatabase Methods

- (NSArray *)yapDatabaseRelationshipEdges {
    NSArray *edges = nil;
    return edges;
}

#pragma mark - Convenience Methods
- (void)encryptPassword:(NSString *)password {
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    if(!self.passwordSalt) {
        [self setSalt];
    }
    unsigned char key[32];
    CCKeyDerivationPBKDF(kCCPBKDF2, passwordData.bytes, passwordData.length, self.passwordSalt.bytes, self.passwordSalt.length, kCCPRFHmacAlgSHA256, 10000, key, 32);
    _passwordCrypt = [NSData dataWithBytes:key length:sizeof(key)];
}

- (void)setSalt {
    _passwordSalt = [self salt];
}

- (NSData *)salt {
    NSString *keychainSaltKey = [NSString stringWithFormat:@"passwordSalt_%@", self.username];
    NSString *passwordSaltString = [SSKeychain passwordForService:keychainService account:keychainSaltKey];
    NSData *passwordSalt;
    if(!passwordSaltString) {
        passwordSalt = [Util generateRandomData:32];
        NSString *newPasswordSaltString = [passwordSalt base64EncodedString];
        [SSKeychain setPassword:newPasswordSaltString forService:keychainService account:keychainSaltKey];
    }else {
        passwordSalt = [passwordSaltString base64DecodedData];
    }
    return passwordSalt;
}

@end
