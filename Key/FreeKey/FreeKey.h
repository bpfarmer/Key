//
//  FreeKey.h
//  Key
//
//  Created by Brendan Farmer on 3/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KEncryptable.h"

@class KUser;
@class EncryptedMessage;
@class PreKeyExchange;
@class PreKeyReceipt;

@interface FreeKey : NSObject

+ (EncryptedMessage *)encryptObject:(id <KEncryptable>)object toUser:(NSString *)userId;
+ (id <KEncryptable>)decryptEncryptedMessage:(EncryptedMessage *)encryptedMessage fromUser:(NSString *)userId;
+ (void)respondToPreKeyExchange:(PreKeyExchange *)preKeyExchange;
+ (void)respondToPreKeyRecript:(PreKeyReceipt *)preKeyReceipt;
+ (void)setupKeysForUser:(KUser *)user;

@end
