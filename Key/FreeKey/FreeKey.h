//
//  FreeKey.h
//  Key
//
//  Created by Brendan Farmer on 3/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KEncryptable.h"

#define kRetrievedPreKeyNotification @"RetrievedPreKeyNotification"
#define kUserRemoteAlias @"user"

@class KUser;
@class EncryptedMessage;
@class PreKeyExchange;
@class PreKeyReceipt;
@class PreKey;
@class Session;

#define kOurPreKeyCollection         @"OurPreKey"
#define kTheirPreKeyCollection       @"TheirPreKey"
#define kSessionCollection           @"Session"
#define kPreKeyExchangeCollection    @"PreKeyExchange"
#define kPreKeyRemoteAlias           @"pre_key"
#define kPreKeyExchangeRemoteAlias   @"pre_key_exchange"
#define kEncryptedMessageRemoteAlias @"message"
#define kFeedRemoteAlias             @"Feed"
#define kOurEncryptedMessageCollection    @"OurEncryptedMessage"
#define kTheirEncryptedMessageCollection  @"TheirEncryptedMessage"

#define kEncryptObjectQueue @"encryptObjectQueue"
#define kDecryptObjectQueue @"decryptObjectQueue"

@interface FreeKey : NSObject

+ (instancetype)sharedManager;

- (EncryptedMessage *)encryptObject:(id <KEncryptable>)object
                          localUser:(KUser *)localUser
                        recipientId:(NSString *)recipientId;

- (id <KEncryptable>)decryptEncryptedMessage:(EncryptedMessage *)encryptedMessage
                                   localUser:(KUser *)localUser
                                    senderId:(NSString *)senderId;

- (Session *)createSessionFromUser:(KUser *)localUser withPreKey:(PreKey *)preKey;
- (Session *)createSessionFromUser:(KUser *)localUser withPreKeyExchange:(PreKeyExchange *)preKeyExchange;
- (NSArray *)generatePreKeysForUser:(KUser *)user;
- (void)sendPreKeysToServer:(NSArray *)preKeys;
- (void)getRemotePreKeyForUserId:(NSString *)recipientId;
- (void)getRemoteUserWithUsername:(NSString *)username;

- (void)receiveRemoteObject:(NSDictionary *)object ofType:(NSString *)type;
- (void)receiveRemoteFeed:(NSDictionary *)objects;
- (PreKey *)createPreKeyFromRemoteDictionary:(NSDictionary *)dictionary;
- (PreKeyExchange *)createPreKeyExchangeFromRemoteDictionary:(NSDictionary *)dictionary;
- (EncryptedMessage *)createEncryptedMessageFromRemoteDictionary:(NSDictionary *)dictionary;

- (void)enqueueEncryptableObject:(id <KEncryptable>)object;

@end
