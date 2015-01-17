//
//  KKeyPair.m
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KKeyPair.h"

@implementation KKeyPair

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

+ (KKeyPair *)createRSAKeyPair {
    KError *error = [[KError alloc] init];
    KRSACryptor *RSACryptor = [[KRSACryptor alloc] init];
    
    KRSACryptorKeyPair *RSAKeyPair = [RSACryptor generateKeyPairWithKeyIdentifier:[NSString stringWithFormat:@"kkeypair_%f", [[NSDate date] timeIntervalSince1970]] error:error];
    
    KKeyPair *keyPair = [[KKeyPair alloc] init];
    keyPair.privateKey = RSAKeyPair.privateKey;
    keyPair.publicKey = RSAKeyPair.publicKey;
    keyPair.encryptionAlgorithm = @"RSA";
    
    return keyPair;
}

@end
