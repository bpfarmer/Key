//
//  KUser.m
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KUser.h"
#import "KCryptor.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "KSettings.h"
#import "KMessage.h"
#import "KStorageManager.h"
#import "KAccountManager.h"
#import "KThread.h"

@implementation KUser

#pragma mark - Initializers

- (instancetype)initWithUsername:(NSString *)username {
    self = [super initWithUniqueId:nil];
    
    if (self) {
        _username = username;
    }

    return self;
}

- (instancetype)initFromRemoteWithUsername:(NSString *)username {
    self = [self initWithUsername:username];
    [self getRemoteUser];
    return self;
}

#pragma mark - User Registration

- (void)registerAccountWithPassword:(NSString *)password {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:kUserUsernameRegistrationEndpoint parameters:@{@"user" : @{@"username" : self.username}} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON FROM USERNAME CHECK: %@", responseObject);
        if([responseObject[@"status"]  isEqual:@"FAILURE"]) {
            [self setStatus:kUserRegisterUsernameFailureStatus];
        }else {
            [self setUniqueId:responseObject[@"user"][@"id"]];
            [self setStatus:kUserRegisterUsernameSuccessStatus];
            [[KAccountManager sharedManager] setUniqueId:[self uniqueId]];
            NSLog(@"HERE HERE");
            [[KStorageManager sharedManager] setObject:self forKey:self.uniqueId inCollection:[[self class] collection]];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self generatePassword:password];
                [self finishRegistration];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kUserRegistrationStatusNotification object:self];
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)finishRegistration {
    KKeyPair *keyPair = [[KKeyPair alloc] initRSA];
    NSDictionary *updatedUserDictionary = @{@"user" : @{@"id"       : self.uniqueId,
                                                        @"password" : self.passwordCrypt,
                                                        @"keyPair"  : [keyPair toDictionary]}};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:kUserFinishRegistrationEndpoint parameters: updatedUserDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON FROM USER PASSWORD: %@", responseObject);
        if([responseObject[@"status"] isEqual:@"SUCCESS"]) {
            [keyPair setUniqueId:responseObject[@"user"][@"keyPair"][@"id"]];
            [keyPair setUserId:[self uniqueId]];
            self.keyPairs = [NSArray arrayWithObject:keyPair];
            [self setStatus:kUserRegisterKeyPairSuccessStatus];
        } else {
            [self setStatus:kUserRegisterKeyPairFailureStatus];
        }
        [[KStorageManager sharedManager] setObject:self forKey:self.uniqueId inCollection:[[self class] collection]];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)generatePassword:(NSString *)password {
    NSDictionary *encryptedPasswordDictionary = [[[KCryptor alloc] init] encryptOneWay: password];
    [self setPasswordCrypt:encryptedPasswordDictionary[@"encrypted"]];
    [self setPasswordSalt:encryptedPasswordDictionary[@"salt"]];
}

#pragma mark - Batch Query Methods

+ (NSArray *)keyPairsForUserIds:(NSArray *)userIds {
    NSMutableArray *keyPairs = [[NSMutableArray alloc] init];
    
    [[[KStorageManager sharedManager] dbConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateObjectsForKeys:userIds inCollection:[self collection] unorderedUsingBlock:^(NSUInteger keyIndex, id object, BOOL *stop) {
            [keyPairs addObject:[object activeKeyPair]];
        }];
    }];
    
    return keyPairs;
}

+ (NSArray *)fullNamesForUserIds:(NSArray *)userIds {
    NSMutableArray *fullNames = [[NSMutableArray alloc] init];
    
    [[[KStorageManager sharedManager] dbConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateRowsForKeys:userIds inCollection:[self collection] unorderedUsingBlock:^(NSUInteger keyIndex, id object, id metadata, BOOL *stop) {
            [fullNames addObject:[object fullName]];
        }];
    }];
    return fullNames;
}


#pragma mark - Adding External Users

- (void)getRemoteUser {
    NSLog(@"HERE AT REMOTE USER");
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:kUserGetUserEndpoint parameters:@{@"user" : @{@"username" : self.username}} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"RETRIEVING USER CHECK: %@", responseObject);
        if([responseObject[@"status"]  isEqual:@"FAILURE"]) {
            [self setStatus:kUserGetRemoteUserFailureStatus];
        }else {
            [self setUniqueId:responseObject[@"user"][@"id"]];
            KKeyPair *keyPair = [[KKeyPair alloc] initFromRemote:responseObject[@"user"][@"keyPair"]];
            self.keyPairs = [NSArray arrayWithObject:keyPair];
            [self setStatus:kUserGetRemoteUserSuccessStatus];
            [[KStorageManager sharedManager] setObject:self forKey:self.uniqueId inCollection:[[self class] collection]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kUserGetRemoteStatusNotification object:self];
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

#pragma mark - Sending Messages

#pragma mark - User Custom Attributes

- (KKeyPair *)activeKeyPair {
    return [self.keyPairs objectAtIndex:0];
}

- (NSString *)fullName {
    return [self username];
}

#pragma mark - YapDatabase Methods

- (NSArray *)yapDatabaseRelationshipEdges {
    NSArray *edges = nil;
    return edges;
}

#pragma mark - Throwaway Methods for Testing

- (void)generateRandomThread {
    KUser *otherUser = [[KUser alloc] initWithUniqueId:@"KUserUniqueId1"];
    [otherUser setUsername:@"Some Stupid User"];
    [[KStorageManager sharedManager] setObject:otherUser forKey:[otherUser uniqueId] inCollection:[KUser collection]];
    NSArray *users = [NSArray arrayWithObjects:[self uniqueId], [otherUser uniqueId], nil];
    KThread *firstThread = [[KThread alloc] initWithUsers:users];
    KMessage *message = [[KMessage alloc] initFrom:[self uniqueId] threadId:[firstThread uniqueId] body:@"SOME DUMB MESSAGE"];
    [[KStorageManager sharedManager] setObject:firstThread forKey:[firstThread uniqueId] inCollection:[[firstThread class] collection]];
    [[KStorageManager sharedManager] setObject:message forKey:[message uniqueId] inCollection:[[message class] collection]];
}

@end
