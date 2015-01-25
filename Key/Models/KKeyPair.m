//
//  KKeyPair.m
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KKeyPair.h"
#import "KError.h"
#import "KRSACryptor.h"
#import "KRSACryptorKeyPair.h"

@implementation KKeyPair

// Specify default values for properties

+ (NSDictionary *)defaultPropertyValues
{
    return @{
      @"publicId" : @"",
      @"privateKey" : @"",
    };
}

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
    keyPair.algorithm = @"RSA";
    
    return keyPair;
}

- (NSString *)encryptText:(NSString *)text {
    KRSACryptor *RSACryptor = [[KRSACryptor alloc] init];
    KError *error = [[KError alloc] init];
    return [RSACryptor encrypt:text
                    key:self.publicKey
                  error:error];

}

- (NSString *)decryptText:(NSString *)textCrypt {
    KRSACryptor *RSACryptor = [[KRSACryptor alloc] init];
    KError *error = [[KError alloc] init];
    return [RSACryptor decrypt:textCrypt
                           key:self.privateKey
                         error:error];
}

- (NSDictionary *)toDictionary {
    return @{
      @"publicKey" : self.publicKey,
      @"algorithm" : self.algorithm
    };
}

- (NSData *)encryptData:(NSData *)data {
    return data;
}

- (NSData *)decryptData:(NSData *)dataCrypt {
    return dataCrypt;
}

- (void)saveInRealm:(RLMRealm *)realm {
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

@end
