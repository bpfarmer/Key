//
//  KUser.m
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KUser.h"

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

+ (BOOL)isUsernameUnique:(NSString *)username {
    return YES;
}

+ (KUser *)createUserWithUsername:(NSString *)username password:(NSString *)password inRealm:(RLMRealm *)realm {
    KUser *user = [[KUser alloc] init];
    user.username = username;
    user.password = password;
    [user addRSAKeyPair];
    if ([user saveInRealm:realm]) {
        return user;
    }else {
        return nil;
    }
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
