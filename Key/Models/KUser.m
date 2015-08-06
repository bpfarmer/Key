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
#import <25519/Curve25519.h>
#import "HttpManager.h"
#import <CommonCrypto/CommonCrypto.h>
#import "Util.h"
#import <SSKeychain/SSKeychain.h>
#import "NSData+Base64.h"
#import "NSString+Base64.h"
#import "KUser+Serialize.h"
#import "PreKey.h"
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
#import "CollapsingFutures.h"

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

+ (TOCFuture *)asyncRetrieveKeyExchangeWithRemoteDeviceId:(NSString *)remoteDeviceId {
    return [GetKeyExchangeRequest makeRequestWithRemoteDeviceId:remoteDeviceId];
}

- (TOCFuture *)asyncGetFeed {
    return [GetMessagesRequest makeRequestWithCurrentUserId:self.uniqueId];
}

+ (TOCFuture *)asyncFindById:(NSString *)uniqueId {
    TOCFutureSource *futureUser = [TOCFutureSource new];
    KUser *user = [self findById:uniqueId];
    if(user != nil) [futureUser trySetResult:user];
    else [futureUser trySetResult:[self asyncRetrieveWithUniqueId:uniqueId]];
    return futureUser.future;
}

- (void)setupIdentityKey {
    self.identityKey = [Curve25519 generateKeyPair];
    [self setPublicKey:self.identityKey.publicKey];
    [self save];
}

#pragma mark - User Custom Attributes

- (NSString *)fullName {
    return [self username];
}

- (NSString *)displayName {
    return [self username];
}

- (NSArray *)contacts {
    return [[KStorageManager sharedManager] querySelectObjects:^NSArray *(FMDatabase *database) {
        FMResultSet *result = [database executeQuery:[NSString stringWithFormat:@"select * from %@ where unique_id <> :unique_id", [self.class tableName]] withParameterDictionary:@{@"unique_id" : self.uniqueId}];
        NSMutableArray *contacts = [[NSMutableArray alloc] init];
        while(result.next) {
            KUser *contact = [[self.class alloc] initWithResultSetRow:result.resultDictionary];
            [contacts addObject:contact];
        }
        [result close];
        return [contacts copy];
    }];
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

+ (NSArray *)remoteKeys {
    return @[@"uniqueId", @"publicKey", @"username"];
}

- (void)setupKeysForDevice {
    [self setCurrentDevice];
    [self setupIdentityKey];
    [self asyncUpdate];
    [FreeKey generatePreKeysForLocalIdentityKey:self.identityKey localDeviceId:self.currentDeviceId];
}

- (void)setCurrentDevice {
    KDevice *device = [[KDevice alloc] initWithUserId:self.uniqueId deviceId:[NSString stringWithFormat:@"%@_%@", self.uniqueId, [[UIDevice currentDevice].identifierForVendor UUIDString]] isCurrentDevice:YES];
    [device save];
    self.currentDeviceId = device.deviceId;
}

- (NSArray *)devices {
    return [KDevice devicesForUserId:self.uniqueId];
}

- (void)addDeviceId:(NSString *)deviceId {
    [KDevice addDeviceForUserId:self.uniqueId deviceId:[NSString stringWithFormat:@"%@_%@", self.uniqueId, deviceId]];
}

@end
