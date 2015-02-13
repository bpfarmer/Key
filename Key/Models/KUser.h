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

@class KKeyPair;

@interface KUser : KYapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic) NSString *firstName;
@property (nonatomic) NSString *lastName;
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *plainPassword;
@property (nonatomic) NSData *passwordSalt;
@property (nonatomic) NSData *passwordCrypt;
@property (nonatomic) NSString *localStatus;
@property (nonatomic) KKeyPair *activeKeyPair;

+ (NSArray *)keyPairsForUserIds:(NSArray *)userIds;
+ (NSArray *)fullNamesForUserIds:(NSArray *)userIds;

+ (NSString *)remoteCreateNotification;

- (instancetype)initWithRemoteUsername:(NSString *)username;
- (instancetype)initWithUsername:(NSString *)username;
- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password;
- (KKeyPair *)activeKeyPair;
- (NSString *)fullName;
- (void)generateRandomThread;

@end

//Notification Center
#define KUserRegisterUsernameStatusNotification @"KUserRegisterUsernameStatusNotification"
