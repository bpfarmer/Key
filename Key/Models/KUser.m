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

#pragma mark - Realm Settings

+ (NSDictionary *)defaultPropertyValues
{
    return @{@"username"       : @"",
             @"publicId"       : @"",
             @"passwordSalt"   : [[NSData alloc] init],
             @"passwordCrypt"  : [[NSData alloc] init],
             @"status"         : @""};
}

- (void)registerUsername:(NSString *)username password:(NSString *)password {
    dispatch_queue_t remote_registration_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(remote_registration_queue, ^(void) {
        //[KUser remoteRegisterUsername:username realmPath:realmPath];
    });

    dispatch_queue_t local_registration_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(local_registration_queue, ^(void) {
        //[KUser localRegistrationWithUsername:self.username password:password];
    });
}

#pragma mark - Local User Registration

+ (void)localRegistrationWithUsername:(NSString *)username password:(NSString *)password realmPath:(NSString *)realmPath {
    //KUser *user = [KUser findByUsername:username realm:realm];
    //[user generateRSAKeyPairInRealm:realm];
    //[user generatePasswordCryptFromPassword:password realm:realm];
}

- (void)generatePasswordCryptFromPassword:(NSString *)password {
    KCryptor *cryptor = [[KCryptor alloc] init];
    NSDictionary *encryptedPasswordDictionary = [cryptor encryptOneWay: password];
    NSDictionary *userDictionary = @{@"passwordCrypt" : encryptedPasswordDictionary[@"key"],
                                     @"passwordSalt"  : encryptedPasswordDictionary[@"salt"]};
    NSLog(@"ENCRYPTED PASSWORD: %@", userDictionary[@"passwordCrypt"]);
}

- (void)generateRSAKeyPair {
    KKeyPair *keyPair = [KKeyPair createRSAKeyPair];
    NSLog(@"PUBLIC KEY: %@", keyPair.publicKey);
}

#pragma mark - Remote User Registration

+ (void)remoteRegisterUsername:(NSString *)username {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"user" : @{@"username" : username}};
    [manager POST:kUserUsernameRegistrationEndpoint parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON FROM USERNAME CHECK: %@", responseObject);
        KUser *user = [[KUser alloc] init];
        if([responseObject[@"status"]  isEqual:@"FAILURE"]) {
            NSDictionary *userDictionary = @{@"status" : kUserRegisterUsernameFailureStatus};
        }else {
            NSDictionary *userDictionary = @{@"publicId" : responseObject[@"user"][@"id"],
                                             @"status"   : kUserRegisterUsernameSuccessStatus};
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

+ (void)remoteFinishRegistration:(NSString *)username {
    KUser *user = [[KUser alloc] init];
    NSDictionary *updatedUserDictionary = @{@"id" : user.publicId,
                                            @"password" : user.passwordCrypt,
                                            @"keyPair"  : [user.activeKeyPair toDictionary]};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"user" : updatedUserDictionary};
    [manager POST:kUserFinishRegistrationEndpoint parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON FROM USER PASSWORD: %@", responseObject);
        KUser *asyncUser = [[KUser alloc] init];
        if([responseObject[@"status"] isEqual:@"FAILURE"]) {
            NSDictionary *keyDictionary = @{@"publicId" : responseObject[@"user"][@"keyPair"][@"id"]};
            NSDictionary *userDictionary = @{@"status" : kUserRegisterKeyPairSuccess};
        } else {
            NSDictionary *userDictionary = @{@"status" : kUserRegisterKeyPairFailure};
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

#pragma mark - Adding External Users

+ (void)addUserWithUsername:(NSString *)username realmPath:(NSString *)realmPath {
    NSDictionary *userDictionary = @{@"users" : @{@"username" : username}};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:kUserGetUsersEndpoint parameters:userDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON FOR ADDITIONAL USER CREATION: %@", responseObject);
        if([responseObject[@"status"] isEqual:@"SUCCESS"]) {
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

+ (void)createUserFromDictionary:(NSDictionary *)userDictionary {
    KUser *user = [[KUser alloc] init];
    user.publicId = userDictionary[@"id"];
    user.username = userDictionary[@"username"];
}

#pragma mark - Methods For External Users

- (void)addPublicKey:(NSDictionary *)keyDictionary {
    KKeyPair *keyPair = [[KKeyPair alloc] init];
    keyPair.publicId = keyDictionary[@"id"];
    keyPair.publicKey = keyDictionary[@"publicKey"];
    keyPair.algorithm = keyDictionary[@"algorithm"];
}

#pragma mark - Sending Messages

- (void)sendMessageText:(NSString *)text toUser:(KUser *)user {
    KMessage *message = [[KMessage alloc] init];
    message.body = text;
    KMessageCrypt *messageCrypt = [message encryptMessageToUser:user];
    NSLog(@"Testing for KeyPair Pub ID: %@", messageCrypt.keyPair.publicId);
    NSDictionary *messageDictionary = @{@"messages" : @[@{@"authorId" : self.publicId,
                                                          @"recipientId" : user.publicId,
                                                          @"bodyCrypt" : messageCrypt.bodyCrypt,
                                                          @"keyPairId" : messageCrypt.keyPair.publicId}]};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:kMessageSendMessagesEndpoint parameters:messageDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON FROM SENDING MESSAGES: %@", responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

#pragma mark - User Custom Attributes

- (KKeyPair *)activeKeyPair {
    return [self.keyPairs objectAtIndex:0];
}

#pragma mark - Realm Setter Methods

+ (void)removeTemporaryUsers {
    NSPredicate *usernamePredicate = [NSPredicate predicateWithFormat:@"username = %@", @""];
    //RLMResults *temporaryUsers = [KUser objectsInRealm:realm withPredicate:usernamePredicate];
}

- (NSArray *)yapDatabaseRelationshipEdges {
    NSArray *edges = nil;
    return edges;
}

@end
