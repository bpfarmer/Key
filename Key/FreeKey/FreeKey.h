//
//  FreeKey.h
//  Key
//
//  Created by Brendan Farmer on 3/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

// TODO: resolve identity key / base key / ECKeyPair naming conventions
#import <Foundation/Foundation.h>
#import "KEncryptable.h"

#define kRetrievedPreKeyNotification @"RetrievedPreKeyNotification"
#define kUserRemoteAlias @"user"

@class ECKeyPair;
@class EncryptedMessage;
@class PreKeyExchange;
@class PreKeyReceipt;
@class PreKey;
@class Session;
@class KDatabaseObject;
@class Attachment;
@class AttachmentKey;

#define kOurPreKeyCollection         @"OurPreKey"
#define kTheirPreKeyCollection       @"TheirPreKey"
#define kSessionCollection           @"Session"
#define kEncryptedMessageCollection  @"EncryptedMessage"
#define kPreKeyExchangeCollection    @"PreKeyExchange"
#define kPreKeyRemoteAlias           @"pre_key"
#define kPreKeyExchangeRemoteAlias   @"pre_key_exchange"
#define kEncryptedMessageRemoteAlias @"message"
#define kAttachmentRemoteAlias       @"attachment"
#define kFeedRemoteAlias             @"feed"
#define kOurEncryptedMessageCollection    @"OurEncryptedMessage"
#define kTheirEncryptedMessageCollection  @"TheirEncryptedMessage"

#define kEncryptObjectQueue @"encryptObjectQueue"
#define kDecryptObjectQueue @"decryptObjectQueue"
#define kFreeKeyQueue @"freeKeyQueue"

@interface FreeKey : NSObject

+ (void)sendEncryptableObject:(KDatabaseObject *)object recipientId:(NSString *)recipientId;
+ (void)decryptAndSaveEncryptedMessage:(EncryptedMessage *)encryptedMessage;

+ (void)sendAttachableObject:(KDatabaseObject *)object recipientIds:(NSArray *)recipientIds;
+ (void)decryptAndSaveAttachment:(Attachment *)attachment;

+ (void)sendEncryptableObject:(KDatabaseObject *)encryptableObject attachableObjects:(NSArray *)attachableObjects recipientIds:(NSArray *)recipientIds;

+ (Session *)processNewKeyExchange:(NSObject *)keyExchange localDeviceId:(NSString *)localDeviceId localIdentityKey:(ECKeyPair *)localIdentityKey;

+ (void)generatePreKeysForLocalIdentityKey:(ECKeyPair *)localIdentityKey localDeviceId:(NSString *)currentDeviceId;

@end
