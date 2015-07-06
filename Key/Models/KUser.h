//
//  KUser.h
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "KDatabaseObject.h"
#import "KSendable.h"

@class IdentityKey;
@class KStorageManager;
@class PreKey;
@class TOCFuture;

@interface KUser : KDatabaseObject <KSendable>

@property (nonatomic) NSString *firstName;
@property (nonatomic) NSString *lastName;
@property (nonatomic) NSString *username;
@property (nonatomic) NSData *passwordSalt;
@property (nonatomic) NSData *passwordCrypt;
@property (nonatomic) NSString *localStatus;
@property (nonatomic) IdentityKey *identityKey;
@property (nonatomic) NSData *publicKey;
@property (nonatomic) BOOL hasLocalPreKey;


+ (KUser *)fetchObjectWithUsername:(NSString *)username;
+ (NSArray *)userIdsWithUsernames:(NSArray *)usernames;
- (void)setPasswordCryptInKeychain:(NSString *)password;
- (BOOL)authenticatePassword:(NSString *)password;

- (instancetype)initWithUsername:(NSString *)username;
- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password;
- (instancetype)initWithUniqueId:(NSString *)uniqueId
                        username:(NSString *)username
                       publicKey:(NSData *)publicKey;
- (instancetype)initWithUniqueId:(NSString *)uniqueId
                        username:(NSString *)username
                   passwordCrypt:(NSData *)passwordCrypt
                    passwordSalt:(NSData *)passwordSalt
                     identityKey:(IdentityKey *)identityKey
                       publicKey:(NSData *)publicKey;

+ (TOCFuture *)asyncCreateWithUsername:(NSString *)username password:(NSString *)password;
+ (TOCFuture *)asyncRetrieveWithUsername:(NSString *)username;
+ (TOCFuture *)asyncRetrieveWithUniqueId:(NSString *)uniqueId;
- (TOCFuture *)asyncRetrieveKeyExchangeWithRemoteUser:(KUser *)remoteUser;
- (TOCFuture *)asyncSetupPreKeys;
- (TOCFuture *)asyncUpdate;
- (TOCFuture *)asyncGetFeed;

- (NSString *)displayName;
- (void)setupIdentityKey;

@end
