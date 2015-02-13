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

@property (nonatomic) NSString *firstName;
@property (nonatomic) NSString *lastName;
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *plainPassword;
@property (nonatomic) NSData *passwordSalt;
@property (nonatomic) NSData *passwordCrypt;
@property (nonatomic) NSString *status;
@property (nonatomic) NSArray *keyPairs;

+ (NSArray *)keyPairsForUserIds:(NSArray *)userIds;
+ (NSArray *)fullNamesForUserIds:(NSArray *)userIds;

- (instancetype)initWithRemoteUsername:(NSString *)username;
- (instancetype)initWithUsername:(NSString *)username;
- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password;
- (KKeyPair *)activeKeyPair;
- (NSString *)fullName;
- (void)generateRandomThread;

@end

//Notification Center
#define kUserRegistrationStatusNotification @"UserRegistrationStatusNotification"
#define kUserGetRemoteStatusNotification @"UserGetRemoteStatusNotification"

//Status Definitions
#define kUserTryRegisterUsernameStatus @"Attempting Registration of Username"
#define kUserRegisterUsernameSuccessStatus @"Successfully Registered Username"
#define kUserRegisterUsernameFailureStatus @"Username Already Taken"
#define kUserRegisterKeyPairSuccessStatus @"Successfully Registered KeyPair"
#define kUserRegisterKeyPairFailureStatus @"Failed to Register KeyPair"
#define kUserGetRemoteUserSuccessStatus @"Successfully Retrieved User"
#define kUserGetRemoteUserFailureStatus @"Failed to Retrieve User"
