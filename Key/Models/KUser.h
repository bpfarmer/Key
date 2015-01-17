//
//  KUser.h
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Realm/Realm.h>
#import "KKeyPair.h"

@interface KUser : RLMObject

@property NSString *username;
@property NSString *password;
@property RLMArray<KKeyPair> *keyPairs;

+ (BOOL)isUsernameUnique:(NSString *)username;
+ (KUser *)createUserWithUsername:(NSString *)username password:(NSString *)password inRealm:(RLMRealm *)realm;
- (BOOL)addRSAKeyPair;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<KUser>
RLM_ARRAY_TYPE(KUser)
