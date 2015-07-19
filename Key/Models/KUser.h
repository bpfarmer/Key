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
@class KDevice;

@interface KUser : KDatabaseObject <KSendable>

@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *localStatus;
@property (nonatomic, copy) NSData *publicKey;
@property (nonatomic, readwrite) IdentityKey *identityKey;
@property (nonatomic) BOOL hasLocalPreKey;

+ (NSData *)salt;
+ (NSData *)encryptPassword:(NSString *)password salt:(NSData *)salt;

- (instancetype)initWithUsername:(NSString *)username;
- (instancetype)initWithUniqueId:(NSString *)uniqueId username:(NSString *)username publicKey:(NSData *)publicKey;

+ (TOCFuture *)asyncCreateWithUsername:(NSString *)username password:(NSString *)password;
+ (TOCFuture *)asyncRetrieveWithUsername:(NSString *)username;
+ (TOCFuture *)asyncRetrieveWithUniqueId:(NSString *)uniqueId;
- (TOCFuture *)asyncRetrieveKeyExchangeWithRemoteUser:(KUser *)remoteUser;
- (TOCFuture *)asyncRetrieveKeyExchangeWithRemoteUser:(KUser *)remoteUser deviceId:(NSString *)deviceId;
- (TOCFuture *)asyncSetupPreKeys;
- (TOCFuture *)asyncUpdate;
- (TOCFuture *)asyncGetFeed;

- (NSString *)displayName;
- (NSArray *)contacts;
- (void)setupIdentityKey;
- (IdentityKey *)identityKey;
- (KDevice *)currentDevice;
- (NSArray *)devices;

@end
