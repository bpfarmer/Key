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
#import "KUser+Serialize.h"
#import "PreKey.h"
#import "FreeKeyNetworkManager.h"
#import "FreeKeySessionManager.h"
#import "PreKeyExchange.h"
#import "RegisterUsernameRequest.h"
#import "GetUserRequest.h"
#import "UpdateUserRequest.h"
#import "UserRequest.h"
#import "GetKeyExchangeRequest.h"
#import "SendPreKeysRequest.h"
#import "GetMessagesRequest.h"
#import "SendPreKeyExchangeRequest.h"

@implementation KUser

#pragma mark - Initializers
- (instancetype)initWithUsername:(NSString *)username {
    self = [super initWithUniqueId:nil];
    if(self) {
        _username = username;
    }
    return self;
}

- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password {
    self = [super initWithUniqueId:nil];
    
    if (self) {
        _username = [username lowercaseString];
        [self setPasswordCryptInKeychain:password];
    }
    return self;
}

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                        username:(NSString *)username
                   passwordCrypt:(NSData *)passwordCrypt
                    passwordSalt:(NSData *)passwordSalt
                     identityKey:(IdentityKey *)identityKey
                       publicKey:(NSData *)publicKey{
    self = [super initWithUniqueId:uniqueId];
    
    if (self) {
        _username      = [username lowercaseString];
        _passwordCrypt = passwordCrypt;
        _passwordSalt  = passwordSalt;
        _identityKey = identityKey;
        _publicKey   = publicKey;
    }
    return self;
}

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                        username:(NSString *)username
                       publicKey:(NSData *)publicKey {
    self = [super initWithUniqueId:uniqueId];
    
    if(self) {
        _username = username;
        _publicKey = publicKey;
    }
    return self;
}

+ (TOCFuture *)asyncCreateWithUsername:(NSString *)username password:(NSString *)password {
    KUser *user = [[KUser alloc] initWithUsername:username password:password];
    return [RegisterUsernameRequest makeRequestWithUser:user];
}

+ (TOCFuture *)asyncRetrieveWithUsername:(NSString *)username {
    return [GetUserRequest makeRequestWithParameters:@{kUserUsername : username}];
}

+ (TOCFuture *)asyncRetrieveWithUniqueId:(NSString *)uniqueId {
    return [GetUserRequest makeRequestWithParameters:@{kUserUniqueId : uniqueId}];
}

- (TOCFuture *)asyncUpdate {
    return [UpdateUserRequest makeRequestWithUser:self];
}

- (TOCFuture *)asyncRetrieveKeyExchangeWithRemoteUser:(KUser *)remoteUser {
    return [GetKeyExchangeRequest makeRequestWithLocalUser:self remoteUser:remoteUser];
}

- (TOCFuture *)asyncSetupPreKeys {
    NSArray *preKeys = [[FreeKeyNetworkManager sharedManager] generatePreKeysForLocalUser:self];
    return [SendPreKeysRequest makeRequestWithPreKeys:preKeys];
}

- (TOCFuture *)asyncGetFeed {
    return [GetMessagesRequest makeRequestWithCurrentUserId:self.uniqueId];
}

- (void)setupIdentityKey {
    IdentityKey *identityKey = [[IdentityKey alloc] initWithKeyPair:[Curve25519 generateKeyPair] userId:self.uniqueId];
    [self setIdentityKey:identityKey];
    [self setPublicKey:identityKey.keyPair.publicKey];
    [self save];
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
    __block NSString *userId;
    [[[KStorageManager sharedManager] dbConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        YapDatabaseQuery *query = [YapDatabaseQuery queryWithFormat:@"WHERE username = ?", username];
        [[transaction ext:KUsernameSQLiteIndex] enumerateKeysMatchingQuery:query usingBlock:^(NSString *collection, NSString *key, BOOL *stop) {
            userId = key;
            *stop = YES;
        }];
    }];
    if(userId) {
        return (KUser *)[[KStorageManager sharedManager] objectForKey:userId inCollection:[KUser collection]];
    }else {
        return nil;
    }
}

+ (NSArray *)userIdsWithUsernames:(NSArray *)usernames {
    NSMutableArray *userIds = [[NSMutableArray alloc] init];
    for(NSString *username in usernames) {
        KUser *user = [self fetchObjectWithUsername:username];
        if(user) [userIds addObject:user.uniqueId];
    }
    return userIds;
}

#pragma mark - User Custom Attributes

- (NSString *)fullName {
    return [self username];
}

- (NSString *)displayName {
    return [self username];
}

#pragma mark - YapDatabase Methods

- (NSArray *)yapDatabaseRelationshipEdges {
    NSArray *edges = nil;
    return edges;
}

#pragma mark - Password Handling Methods
- (NSData *)encryptPassword:(NSString *)password {
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    if(!self.passwordSalt) {
        [self setSalt];
    }
    unsigned char key[32];
    CCKeyDerivationPBKDF(kCCPBKDF2, passwordData.bytes, passwordData.length, self.passwordSalt.bytes, self.passwordSalt.length, kCCPRFHmacAlgSHA256, 8000, key, 32);
    return [NSData dataWithBytes:key length:sizeof(key)];
}

- (void)setPasswordCryptInKeychain:(NSString *)password {
    _passwordCrypt = [self encryptPassword:password];
    NSString *keychainPasswordKey = [NSString stringWithFormat:@"password_%@", self.username];
    NSString *passwordString = [self.passwordCrypt base64EncodedString];
    [SSKeychain setPassword:passwordString forService:keychainService account:keychainPasswordKey];
}

- (NSString *)getPasswordCryptFromKeychain {
    NSString *keychainPasswordKey = [NSString stringWithFormat:@"password_%@", self.username];
    return [SSKeychain passwordForService:keychainService account:keychainPasswordKey];
}

- (BOOL)authenticatePassword:(NSString *)password {
    // TODO: eventually do remote authentication
    NSData *passwordCrypt = [self encryptPassword:password];
    return [[passwordCrypt base64EncodedString] isEqual:[self getPasswordCryptFromKeychain]];
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

+ (NSArray *)remoteKeys {
    return @[@"uniqueId", @"passwordCrypt", @"publicKey", @"username"];
}

@end
