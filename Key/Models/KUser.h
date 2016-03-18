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

@class ECKeyPair;
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
@property (nonatomic, readwrite) ECKeyPair *identityKey;
@property (nonatomic) BOOL hasLocalPreKey;
@property (nonatomic, copy) NSString *currentDeviceId;

+ (NSData *)salt;
+ (NSData *)encryptPassword:(NSString *)password salt:(NSData *)salt;

- (instancetype)initWithUsername:(NSString *)username;
- (instancetype)initWithUniqueId:(NSString *)uniqueId username:(NSString *)username publicKey:(NSData *)publicKey;

+ (TOCFuture *)asyncCreateWithUsername:(NSString *)username password:(NSString *)password;
+ (TOCFuture *)asyncRetrieveWithUsername:(NSString *)username;
+ (TOCFuture *)asyncRetrieveWithUniqueId:(NSString *)uniqueId;
+ (TOCFuture *)asyncRetrieveKeyExchangeWithRemoteDeviceId:(NSString *)remoteDeviceId;
- (TOCFuture *)asyncUpdate;
- (TOCFuture *)asyncGetFeed;
+ (TOCFuture *)asyncFindById:(NSString *)uniqueId;
+ (TOCFuture *)asyncFindByIds:(NSArray *)uniqueIds;

- (NSString *)displayName;
- (NSArray *)contacts;
- (void)setupIdentityKey;
- (void)setupKeysForDevice;
- (NSArray *)devices;
- (void)setCurrentDevice;
- (void)addDeviceId:(NSString *)deviceId;

@end
