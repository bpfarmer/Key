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
#import "KDevice.h"

@implementation KUser

#pragma mark - Initializers
- (instancetype)initWithUsername:(NSString *)username {
    self = [super initWithUniqueId:nil];
    if(self) _username = username;
    return self;
}

- (instancetype)initWithUniqueId:(NSString *)uniqueId username:(NSString *)username publicKey:(NSData *)publicKey {
    self = [super initWithUniqueId:uniqueId];
    
    if(self) {
        _username = username;
        _publicKey = publicKey;
    }
    return self;
}

+ (TOCFuture *)asyncCreateWithUsername:(NSString *)username password:(NSString *)password {
    KUser *user = [[KUser alloc] initWithUsername:username];
    NSData *salt = [self salt];
    NSData *passwordCrypt = [self encryptPassword:password salt:salt];
    return [RegisterUsernameRequest makeRequestWithUser:user password:passwordCrypt salt:salt];
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

- (TOCFuture *)asyncRetrieveKeyExchangeWithRemoteUser:(KUser *)remoteUser deviceId:(NSString *)deviceId {
    return [GetKeyExchangeRequest makeRequestWithLocalUser:self remoteUser:remoteUser deviceId:deviceId];
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
    [identityKey save];
    [self setPublicKey:identityKey.keyPair.publicKey];
    [self save];
}

- (IdentityKey *)identityKey {
    return [IdentityKey findByDictionary:@{@"userId" : self.uniqueId}];
}

#pragma mark - User Custom Attributes

- (NSString *)fullName {
    return [self username];
}

- (NSString *)displayName {
    return [self username];
}

- (NSArray *)contacts {
    FMResultSet *resultSet = [[KStorageManager sharedManager] querySelect:^FMResultSet *(FMDatabase *database) {
        return [database executeQuery:[NSString stringWithFormat:@"select * from %@ where unique_id <> :unique_id", [self.class tableName]] withParameterDictionary:@{@"unique_id" : self.uniqueId}];
    }];
    
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    while(resultSet.next) {
        KUser *contact = [[self.class alloc] initWithResultSetRow:resultSet.resultDictionary];
        [contacts addObject:contact];
    }
    [resultSet close];
    return contacts;
}

#pragma mark - Password Handling Methods
+ (NSData *)encryptPassword:(NSString *)password salt:(NSData *)salt {
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char key[32];
    CCKeyDerivationPBKDF(kCCPBKDF2, passwordData.bytes, passwordData.length, salt.bytes, salt.length, kCCPRFHmacAlgSHA256, 8000, key, 32);
    return [NSData dataWithBytes:key length:sizeof(key)];
}

+ (NSData *)salt {
    return [Util generateRandomData:32];
}

- (void)setIdentityKey:(IdentityKey *)identityKey {
    identityKey.userId = self.uniqueId;
    [identityKey save];
}

+ (NSArray *)remoteKeys {
    return @[@"uniqueId", @"publicKey", @"username"];
}

- (void)setupKeysForDevice {
    [self setCurrentDevice];
    [self setupIdentityKey];
    [self asyncUpdate];
    [self asyncSetupPreKeys];
}

- (void)setCurrentDevice {
    KDevice *device = [[KDevice alloc] initWithUserId:self.uniqueId deviceId:[NSString stringWithFormat:@"%@_%@", self.uniqueId, [[UIDevice currentDevice].identifierForVendor UUIDString]] isCurrentDevice:YES];
    [device save];
}

- (KDevice *)currentDevice {
    return [KDevice findByDictionary:@{@"userId" : self.uniqueId, @"isCurrentDevice" : @YES}];
}

- (NSArray *)devices {
    FMResultSet *resultSet = [[KStorageManager sharedManager] querySelect:^FMResultSet *(FMDatabase *database) {
        return [database executeQuery:[NSString stringWithFormat:@"select * from %@ where user_id = :unique_id", [KDevice tableName]] withParameterDictionary:@{@"unique_id" : self.uniqueId}];
    }];
    
    NSMutableArray *devices = [[NSMutableArray alloc] init];
    while(resultSet.next) {
        KDevice *device = [[KDevice alloc] initWithResultSetRow:resultSet.resultDictionary];
        [devices addObject:device];
    }
    [resultSet close];
    return devices;
}

- (void)addDeviceId:(NSString *)deviceId {
    KDevice *device = [[KDevice alloc] initWithUserId:self.uniqueId deviceId:[NSString stringWithFormat:@"%@_%@", self.uniqueId, [[UIDevice currentDevice].identifierForVendor UUIDString]] isCurrentDevice:NO];
    [device save];
}

@end
