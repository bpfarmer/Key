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
#import "KSendable.h"

@class IdentityKey;

@interface KUser : KYapDatabaseObject <YapDatabaseRelationshipNode, KSendable>

@property (nonatomic) NSString *firstName;
@property (nonatomic) NSString *lastName;
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *plainPassword;
@property (nonatomic) NSData *passwordSalt;
@property (nonatomic) NSData *passwordCrypt;
@property (nonatomic) NSString *localStatus;
@property (nonatomic) IdentityKey *identityKey;

// KSendable Protocol
@property (nonatomic) NSString *remoteStatus;

- (instancetype)initWithUsername:(NSString *)username;
- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password;

@end

//Notification Center
#define KUserRegisterUsernameStatusNotification @"KUserRegisterUsernameStatusNotification"
