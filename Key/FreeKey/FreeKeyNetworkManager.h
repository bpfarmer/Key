//
//  FreeKeyPushManager.h
//  Key
//
//  Created by Brendan Farmer on 3/20/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KEncryptable.h"

#define kPreKeyRemoteAlias           @"pre_key"
#define kPreKeyExchangeRemoteAlias   @"pre_key_exchange"
#define kEncryptedMessageRemoteAlias @"message"
#define kFeedRemoteAlias             @"feed"

@class PreKey;
@class PreKeyExchange;
@class EncryptedMessage;
@class KUser;

@interface FreeKeyNetworkManager : NSObject

+ (instancetype)sharedManager;

- (void)receiveRemoteObject:(NSDictionary *)object ofType:(NSString *)type;
- (void)receiveRemoteFeed:(NSDictionary *)objects withLocalUser:(KUser *)localUser;
- (PreKey *)createPreKeyFromRemoteDictionary:(NSDictionary *)dictionary;
- (PreKeyExchange *)createPreKeyExchangeFromRemoteDictionary:(NSDictionary *)dictionary;
- (EncryptedMessage *)createEncryptedMessageFromRemoteDictionary:(NSDictionary *)dictionary;

- (void)enqueueEncryptableObject:(id <KEncryptable>)object localUser:(KUser *)localUser remoteUser:(KUser *)remoteUser;
- (void)enqueueDecryptableObject:(EncryptedMessage *)object toLocalUser:(KUser *)localUser;
- (void)enqueueGetRequestWithRemoteAlias:(NSString *)remoteAlias parameters:(NSDictionary *)parameters;

- (void)pollFeedForLocalUser:(KUser *)localUser;
- (void)sendPreKeysToServer:(NSArray *)preKeys;
- (void)sendPreKeyExchange:(PreKeyExchange *)preKeyExchange toRemoteUser:(KUser *)remoteUser;
- (void)getPreKeyWithRemoteUser:(KUser *)remoteUser;
- (NSArray *)generatePreKeysForLocalUser:(KUser *)localUser;

@end
