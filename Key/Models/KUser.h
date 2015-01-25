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

+ (void)addUserWithUsername:(NSString *)username;

- (void)registerUsername:(NSString *)username;
- (void)localRegistrationWithPassword:(NSString *)password;
- (void)sendMessageText:(NSString *)text toUser:(KUser *)user;
- (KKeyPair *)activeKeyPair;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<KUser>
RLM_ARRAY_TYPE(KUser)

//API Endpoints
#define kUserUsernameRegistrationEndpoint @"http://127.0.0.1:9393/user.json"
#define kUserFinishRegistrationEndpoint @"http://127.0.0.1:9393/user.json"
#define kUserGetUsersEndpoint @"http://127.0.0.1:9393/users.json"

//Status Definitions
#define kUserTryRegisterUsernameStatus @"Attempting Registration of Username"
#define kUserRegisterUsernameSuccessStatus @"Successfully Registered Username"
#define kUserRegisterUsernameFailureStatus @"Username Already Taken"
#define kUserRegisterKeyPairSuccess @"Successfully Registered KeyPair"
#define kUserRegisterKeyPairFailure @"Failed to Register KeyPair"
