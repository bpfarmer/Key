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

+ (KUser *)registerUsername:(NSString *)username {
    KUser *user = [[KUser alloc] init];
    user.username = username;
    NSDictionary *userDictionary =
    @{
      @"users" : @[@{
        @"username" : user.username
      }]
    };
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = userDictionary;
    [manager POST:kUsernameRegistrationEndpoint parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
    return user;
}

- (NSString *)finishRegistrationWithPassword:(NSString *)password {
    NSDictionary *passwordCryptDictionary = [self generatePasswordCryptFromPassword:password];
    [self addRSAKeyPair];
    self.status = @"completed";
    return self.status;
}

- (NSDictionary *)generatePasswordCryptFromPassword:(NSString *)password {
    KCryptor *cryptor = [[KCryptor alloc] init];
    NSDictionary *encryptedPasswordDictionary = [cryptor encryptOneWay: password];
    self.passwordCrypt = encryptedPasswordDictionary[@"key"];
    self.passwordSalt  = encryptedPasswordDictionary[@"salt"];
    
    NSLog(@"%@", self.passwordCrypt);
    return encryptedPasswordDictionary;
}

- (BOOL)addRSAKeyPair {
    KKeyPair *keyPair = [KKeyPair createRSAKeyPair];
    [self.keyPairs addObject:keyPair];
    return YES;
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
