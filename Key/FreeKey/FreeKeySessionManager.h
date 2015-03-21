//
//  FreeKeySessionManager.h
//  Key
//
//  Created by Brendan Farmer on 3/20/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Session;
@class KUser;
@class PreKey;
@class PreKeyExchange;
@class ECKeyPair;

@interface FreeKeySessionManager : NSObject

+ (instancetype)sharedManager;

- (Session *)sessionWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser;
- (Session *)createSessionWithLocalUser:(KUser *)localUser remoteUser:(KUser *)remoteUser;
- (Session *)createSessionWithLocalUser:(KUser *)localUser
                             remoteUser:(KUser *)remoteUser
                             ourBaseKey:(ECKeyPair *)ourBaseKey
                            theirPreKey:(PreKey *)theirPreKey;
- (Session *)createSessionWithLocalUser:(KUser *)localUser
                             remoteUser:(KUser *)remoteUser
                              ourPreKey:(PreKey *)ourPreKey
                    theirPreKeyExchange:(PreKeyExchange *)theirPreKeyExchange;

- (PreKey *)getPreKeyForUserId:(NSString *)userId;
- (NSArray *)generatePreKeysForLocalUser:(KUser *)localUser;

@end
