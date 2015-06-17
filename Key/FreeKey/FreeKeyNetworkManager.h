//
//  FreeKeyPushManager.h
//  Key
//
//  Created by Brendan Farmer on 3/20/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KEncryptable.h"

@class PreKey;
@class PreKeyExchange;
@class EncryptedMessage;
@class KUser;

@interface FreeKeyNetworkManager : NSObject

+ (instancetype)sharedManager;

- (void)enqueueDecryptableMessage:(EncryptedMessage *)encryptedMessage toLocalUser:(KUser *)localUser;
- (void)sendEncryptedMessage:(EncryptedMessage *)encryptedMessage;
- (NSArray *)generatePreKeysForLocalUser:(KUser *)localUser;

@end
