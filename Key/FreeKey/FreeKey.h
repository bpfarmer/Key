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

@class KUser;
@class EncryptedMessage;
@class PreKeyExchange;
@class PreKeyReceipt;
@class PreKey;
@class Session;

@interface FreeKey : NSObject

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

@end
