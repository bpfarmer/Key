//
//  KUser.h
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Realm/Realm.h>
#import "KKeyPair.h"
#import "KGroup.h"

@interface KUser : RLMObject

@property NSString *publicId;
@property NSString *username;
@property NSData *passwordSalt;
@property NSData *passwordCrypt;
@property NSString *status;
@property RLMArray<KKeyPair> *keyPairs;
@property RLMArray<KGroup> *groups;

- (void)registerUsername:(NSString *)username password:(NSString *)password;
- (void)finishRegistrationWithPassword:(NSString *)password;
- (KKeyPair *)addRSAKeyPair;
- (KKeyPair *)activeKeyPair;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<KUser>
RLM_ARRAY_TYPE(KUser)
