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

#pragma mark - Local User Registration

- (void)localRegistrationWithPassword:(NSString *)password {
    [self generateRSAKeyPair];
    [self generatePasswordCryptFromPassword:password];
    // WRITE
}

- (void)generatePasswordCryptFromPassword:(NSString *)password {
    KCryptor *cryptor = [[KCryptor alloc] init];
    NSDictionary *encryptedPasswordDictionary = [cryptor encryptOneWay: password];
    [self setPasswordCrypt:encryptedPasswordDictionary[@"encrypted"]];
    [self setPasswordSalt:encryptedPasswordDictionary[@"salt"]];
    NSLog(@"PASSWORD ENCRYPTED: %@", [self passwordCrypt]);
}

- (void)generateRSAKeyPair {
    [self.keyPairs addObject:[KKeyPair createRSAKeyPair]];
    NSLog(@"PUBLIC KEY: %@", [[self.keyPairs objectAtIndex:0] publicKey]);
}

#pragma mark - Remote User Registration

- (void)remoteRegisterUsername {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"user" : @{@"username" : self.username}};
    [manager POST:kUserUsernameRegistrationEndpoint parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON FROM USERNAME CHECK: %@", responseObject);
        if([responseObject[@"status"]  isEqual:@"FAILURE"]) {
            [self setStatus:kUserRegisterUsernameFailureStatus];
        }else {
            [self setUniqueId:responseObject[@"user"][@"id"]];
            [self setStatus:kUserRegisterUsernameSuccessStatus];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)remoteFinishRegistration {
    NSDictionary *updatedUserDictionary = @{@"user" : @{@"id"       : self.uniqueId,
                                                        @"password" : self.passwordCrypt,
                                                        @"keyPair"  : [self.activeKeyPair toDictionary]}};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:kUserFinishRegistrationEndpoint parameters: updatedUserDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON FROM USER PASSWORD: %@", responseObject);
        if([responseObject[@"status"] isEqual:@"FAILURE"]) {
            [[self.keyPairs lastObject] setUniqueId:responseObject[@"user"][@"keyPair"][@"id"]];
            [self setStatus:kUserRegisterKeyPairSuccess];
            //WRITE
        } else {
            [self setStatus:kUserRegisterKeyPairFailure];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
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
