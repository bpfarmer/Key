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

@implementation KUser

- (instancetype)initWithUsername:(NSString *)username {
    self = [super initWithUniqueId:nil];
        
    if (self) {
        _username = username;
    }
        
    return self;
}

#pragma mark - User Registration

- (void)registerPassword:(NSString *)password {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"user" : @{@"username" : self.username}};
    [manager POST:kUserUsernameRegistrationEndpoint parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON FROM USERNAME CHECK: %@", responseObject);
        if([responseObject[@"status"]  isEqual:@"FAILURE"]) {
            [self setStatus:kUserRegisterUsernameFailureStatus];
        }else {
            [self setUniqueId:responseObject[@"user"][@"id"]];
            [self setStatus:kUserRegisterUsernameSuccessStatus];
            //WRITE
            [self finishRegistrationPassword:password];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)finishRegistrationPassword:(NSString *)password {
    [self localGeneratePassword:password];
    KKeyPair *keyPair = [KKeyPair createRSAKeyPair];
    NSDictionary *updatedUserDictionary = @{@"user" : @{@"id"       : self.uniqueId,
                                                        @"password" : self.passwordCrypt,
                                                        @"keyPair"  : [keyPair toDictionary]}};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:kUserFinishRegistrationEndpoint parameters: updatedUserDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON FROM USER PASSWORD: %@", responseObject);
        if([responseObject[@"status"] isEqual:@"FAILURE"]) {
            [keyPair setUniqueId:responseObject[@"user"][@"keyPair"][@"id"]];
            [self.keyPairs addObject:keyPair];
            [self setStatus:kUserRegisterKeyPairSuccess];
        } else {
            [self setStatus:kUserRegisterKeyPairFailure];
        }
        //WRITE
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)localGeneratePassword:(NSString *)password {
    NSDictionary *encryptedPasswordDictionary = [[[KCryptor alloc] init] encryptOneWay: password];
    [self setPasswordCrypt:encryptedPasswordDictionary[@"encrypted"]];
    [self setPasswordSalt:encryptedPasswordDictionary[@"salt"]];
    NSLog(@"PASSWORD ENCRYPTED: %@", [self passwordCrypt]);
}

#pragma mark - Adding External Users

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
