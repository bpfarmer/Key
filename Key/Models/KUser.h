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

@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSData *passwordSalt;
@property (nonatomic, copy) NSData *passwordCrypt;
@property (nonatomic, copy) NSString *localStatus;
@property (nonatomic, weak) IdentityKey *identityKey;
@property (nonatomic, weak) NSData *publicKey;
@property (nonatomic) BOOL hasLocalPreKey;

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
