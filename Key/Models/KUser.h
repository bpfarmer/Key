//
//  KUser.h
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <YapDatabase/YapDatabaseRelationshipNode.h>
#import "KYapDatabaseObject.h"
#import "KKeyPair.h"
#import "KGroup.h"

@interface KUser : KYapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic) NSString *username;
@property (nonatomic) NSData *passwordSalt;
@property (nonatomic) NSData *passwordCrypt;
@property (nonatomic) NSString *status;
@property (nonatomic) NSArray *keyPairs;
@property (nonatomic) NSArray *groups;

+ (void)addUserWithUsername:(NSString *)username realmPath:(NSString *)realmPath;
+ (void)remoteFinishRegistration:(NSString *)username realmPath:(NSString *)realmPath;
//+ (KUser *)findByUsername:(NSString *)username realm:(RLMRealm *)realm;

- (void)registerUsername:(NSString *)username password:(NSString *)password; //realm:(RLMRealm *)realm;
- (void)sendMessageText:(NSString *)text toUser:(KUser *)user;
- (KKeyPair *)activeKeyPair;

@end

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
