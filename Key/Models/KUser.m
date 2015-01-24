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

// Specify default values for properties

//+ (NSDictionary *)defaultPropertyValues
//{
//    return @{};
//}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

- (void)registerUsername:(NSString *)username password:(NSString *)password {
    self.username = username;
    NSDictionary *userDictionary =
    @{
      @"user" : @{
        @"username" : self.username
      }
    };
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = userDictionary;
    [manager POST:kUserUsernameRegistrationEndpoint parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        if([responseObject[@"status"]  isEqual:@"FAILURE"]) {
            self.status = @"Failed to reserve username.";
        }else {
            self.status = @"Succeeded in reserving username.";
            self.publicId = responseObject[@"user"][@"publicId"];
            [self finishRegistrationWithPassword:password];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        self.status = @"Failed to reserve username.";
    }];
}

- (void)finishRegistrationWithPassword:(NSString *)password {
    [self generatePasswordCryptFromPassword:password];
    KKeyPair *keyPair = [self generateRSAKeyPair];
    NSDictionary *updatedUserDictionary = @{
      @"user" : @{
        @"publicId" : self.publicId,
        @"password" : self.passwordCrypt,
        @"keyPair"  : [keyPair toDictionary]
      }
    };
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = updatedUserDictionary;
    [manager POST:kUserFinishRegistrationEndpoint parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

+ (void)addUserWithUsername:(NSString *)username {
    NSDictionary *userDictionary = @{
    @"users" : @{
        @"username" : username
    }};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:kUserGetUsersEndpoint parameters:userDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        [KUser createUserFromDictionary:responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

+ (KUser *)createUserFromDictionary:(NSDictionary *)userDictionary {
    KUser *user = [[KUser alloc] init];
    user.publicId = userDictionary[@"publicId"];
    user.username = userDictionary[@"username"];
    [user addPublicKey:userDictionary[@"keyPair"]];
    return user;
}

- (void)sendMessageText:(NSString *)text toUser:(KUser *)user {
    KMessage *message = [[KMessage alloc] init];
    KMessageCrypt *messageCrypt = [message encryptMessageToUser:user];
    NSDictionary *messageDictionary = @{
    @"messages" : @[@{
        @"authorId" : self.publicId,
        @"recipientId" : user.publicId,
        @"bodyCrypt" : messageCrypt.bodyCrypt,
        @"keyPairId" : messageCrypt.keyPair.publicId
    }]};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:kMessageSendMessagesEndpoint parameters:messageDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
}

- (void)addPublicKey:(NSDictionary *)keyDictionary {
    KKeyPair *keyPair = [[KKeyPair alloc] init];
    keyPair.publicId = keyDictionary[@"publicId"];
    keyPair.publicKey = keyDictionary[@"publicKey"];
    keyPair.algorithm = keyDictionary[@"algorithm"];
    [self.keyPairs addObject:keyPair];
}

- (NSDictionary *)generatePasswordCryptFromPassword:(NSString *)password {
    KCryptor *cryptor = [[KCryptor alloc] init];
    NSDictionary *encryptedPasswordDictionary = [cryptor encryptOneWay: password];
    self.passwordCrypt = encryptedPasswordDictionary[@"key"];
    self.passwordSalt  = encryptedPasswordDictionary[@"salt"];
    return encryptedPasswordDictionary;
}

- (KKeyPair *)generateRSAKeyPair {
    KKeyPair *keyPair = [KKeyPair createRSAKeyPair];
    [self.keyPairs addObject:keyPair];
    return keyPair;
}

- (KKeyPair *)activeKeyPair {
    return [self.keyPairs objectAtIndex:0];
}

- (BOOL)saveInRealm:(RLMRealm *)realm {
    //[realm beginWriteTransaction];
    //[realm addObject:self];
    //[realm commitWriteTransaction];
    
    NSLog(@"%@", [realm path]);
    return YES;
}

@end
