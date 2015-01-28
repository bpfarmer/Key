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
#import "KMessageCrypt.h"
#import "KStorageManager.h"

@implementation KUser

- (instancetype)initWithUsername:(NSString *)username {
    self = [super initWithUniqueId:nil];
    
    if (self) {
        _username = username;
    }

    return self;
}

#pragma mark - User Registration

- (void)registerWithPassword:(NSString *)password {
    NSDictionary *parameters = @{@"user" : @{@"username" : self.username}};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:kUserUsernameRegistrationEndpoint parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON FROM USERNAME CHECK: %@", responseObject);
        if([responseObject[@"status"]  isEqual:@"FAILURE"]) {
            [self setStatus:kUserRegisterUsernameFailureStatus];
        }else {
            [self setUniqueId:responseObject[@"user"][@"id"]];
            [self setStatus:kUserRegisterUsernameSuccessStatus];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[KStorageManager sharedManager] setObject:self forKey:self.uniqueId inCollection:@"users"];
                [self generatePassword:password];
                [self finishRegistration];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UserStatusNotification" object:self];
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
            self.keyPairs = [NSArray arrayWithObject:keyPair];
            [self setStatus:kUserRegisterKeyPairSuccessStatus];
            [[KStorageManager sharedManager] setObject:self forKey:self.uniqueId inCollection:@"users"];
        } else {
            [self setStatus:kUserRegisterKeyPairFailureStatus];
        }
        KUser *user = [[KStorageManager sharedManager] objectForKey:self.uniqueId inCollection:@"users"];
        NSLog(@"PERSISTENT USER PUBLIC KEY: %@", [[user.keyPairs objectAtIndex:0] publicKey]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)generatePassword:(NSString *)password {
    NSDictionary *encryptedPasswordDictionary = [[[KCryptor alloc] init] encryptOneWay: password];
    [self setPasswordCrypt:encryptedPasswordDictionary[@"encrypted"]];
    [self setPasswordSalt:encryptedPasswordDictionary[@"salt"]];
    NSLog(@"PASSWORD ENCRYPTED: %@", [self passwordCrypt]);
}

#pragma mark - Adding External Users
- (void)addFromRemote {
    NSDictionary *parameters = @{@"user" : @{@"username" : self.username}};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:kUserGetUserEndpoint parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"RETRIEVING USER CHECK: %@", responseObject);
        if([responseObject[@"status"]  isEqual:@"FAILURE"]) {
            [self setStatus:kUserGetUserFailureStatus];
        }else {
            [self setUniqueId:responseObject[@"user"][@"id"]];
            KKeyPair *keyPair = [[KKeyPair alloc] initFromRemote:responseObject[@"user"][@"keyPair"]];
            self.keyPairs = [NSArray arrayWithObject:keyPair];
            [self setStatus:kUserGetUserSuccessStatus];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UserStatusNotification" object:self];
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}


#pragma mark - Methods For External Users

#pragma mark - Sending Messages

#pragma mark - User Custom Attributes

- (KKeyPair *)activeKeyPair {
    return [self.keyPairs objectAtIndex:0];
}

#pragma mark - YapDatabase Methods

- (NSArray *)yapDatabaseRelationshipEdges {
    NSArray *edges = nil;
    return edges;
}

@end
