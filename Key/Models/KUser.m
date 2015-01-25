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

#pragma mark - User Registration

- (void)localRegistrationWithPassword:(NSString *)password {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [self addToRealm:realm];
    [self generatePasswordCryptFromPassword:password realm:realm];
    [self generateRSAKeyPairInRealm:realm];
}

- (NSDictionary *)generatePasswordCryptFromPassword:(NSString *)password realm:(RLMRealm *)realm {
    KCryptor *cryptor = [[KCryptor alloc] init];
    NSDictionary *encryptedPasswordDictionary = [cryptor encryptOneWay: password];
    NSDictionary *userDictionary = @{@"passwordCrypt" : encryptedPasswordDictionary[@"key"],
                                     @"passwordSalt"  : encryptedPasswordDictionary[@"salt"]};
    [self updateAttributes:userDictionary realm:realm];
    return encryptedPasswordDictionary;
}

- (void)generateRSAKeyPairInRealm:(RLMRealm *)realm {
    KKeyPair *keyPair = [KKeyPair createRSAKeyPair];
    [self updateKeyPairs:keyPair realm:realm];
}

- (void)registerUsername:(NSString *)username {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"user" : @{@"username" : username}};
    [manager POST:kUserUsernameRegistrationEndpoint parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON FROM USERNAME CHECK: %@", responseObject);
        RLMRealm *realm = [RLMRealm defaultRealm];
        if([responseObject[@"status"]  isEqual:@"FAILURE"]) {
            NSDictionary *userDictionary = @{@"status" : kUserRegisterUsernameFailureStatus};
            [self updateAttributes:userDictionary realm:realm];
        }else {
            NSDictionary *userDictionary = @{@"publicId" : responseObject[@"user"][@"id"],
                                             @"status"   : kUserRegisterUsernameSuccessStatus};
            [self updateAttributes:userDictionary realm:realm];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)finishRemoteRegistration {
    NSDictionary *updatedUserDictionary = @{@"id" : self.publicId,
                                            @"password" : self.passwordCrypt,
                                            @"keyPair"  : [self.activeKeyPair toDictionary]};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"user" : updatedUserDictionary};
    [manager POST:kUserFinishRegistrationEndpoint parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON FROM USER PASSWORD: %@", responseObject);
        RLMRealm *realm = [RLMRealm defaultRealm];
        if([responseObject[@"status"] isEqual:@"FAILURE"]) {
            NSDictionary *keyDictionary = @{@"publicId" : responseObject[@"user"][@"keyPair"][@"id"]};
            [self.activeKeyPair updateAttributes:keyDictionary realm:realm];
            
            NSDictionary *userDictionary = @{@"status" : kUserRegisterKeyPairSuccess};
            [self updateAttributes:userDictionary realm:realm];
        } else {
            NSDictionary *userDictionary = @{@"status" : kUserRegisterKeyPairFailure};
            [self updateAttributes:userDictionary realm:realm];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

#pragma mark - Adding External Users

+ (void)addUserWithUsername:(NSString *)username {
    NSDictionary *userDictionary = @{@"users" : @{@"username" : username}};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:kUserGetUsersEndpoint parameters:userDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON FOR ADDITIONAL USER CREATION: %@", responseObject);
        RLMRealm *realm = [[RLMRealm alloc] init];
        if([responseObject[@"status"] isEqual:@"SUCCESS"]) {
            [KUser createUserFromDictionary:responseObject realm:realm];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

+ (void)createUserFromDictionary:(NSDictionary *)userDictionary realm:(RLMRealm *)realm {
    KUser *user = [[KUser alloc] init];
    user.publicId = userDictionary[@"id"];
    user.username = userDictionary[@"username"];
    [user addToRealm:realm];
    [user addPublicKey:userDictionary[@"keyPair"] realm:realm];
}

#pragma mark - Methods For External Users

- (void)addPublicKey:(NSDictionary *)keyDictionary realm:(RLMRealm *)realm {
    KKeyPair *keyPair = [[KKeyPair alloc] init];
    keyPair.publicId = keyDictionary[@"id"];
    keyPair.publicKey = keyDictionary[@"publicKey"];
    keyPair.algorithm = keyDictionary[@"algorithm"];
    [self updateKeyPairs:keyPair realm:realm];
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

- (void)addToRealm:(RLMRealm *)realm {
    [realm beginWriteTransaction];
    [realm addObject:self];
    [realm commitWriteTransaction];
}

- (void)updateAttributes:(NSDictionary *)attributeDictionary realm:(RLMRealm *)realm {
    [realm beginWriteTransaction];
    for(id key in attributeDictionary) {
        [self setValue:attributeDictionary[key] forKey:key];
    }
    [realm commitWriteTransaction];
}

- (void)updateKeyPairs:(KKeyPair *)keyPair realm:(RLMRealm *)realm {
    [realm beginWriteTransaction];
    [self.keyPairs addObject:keyPair];
    [realm commitWriteTransaction];
}

@end
