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

- (NSArray *)yapDatabaseRelationshipEdges {
    NSArray *edges = nil;
    return edges;
}

@end
