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

- (instancetype)initRSA {
    self = [super initWithUniqueId:nil];
    
    if (self) {
        KError *error = [[KError alloc] init];
        KRSACryptor *RSACryptor = [[KRSACryptor alloc] init];
        
        KRSACryptorKeyPair *RSAKeyPair = [RSACryptor generateKeyPairWithKeyIdentifier:[NSString stringWithFormat:@"kkeypair_%f", [[NSDate date] timeIntervalSince1970]] error:error];
        _privateKey = RSAKeyPair.privateKey;
        _publicKey = RSAKeyPair.publicKey;
        _algorithm = @"RSA";
    }
    
    return self;
}

- (instancetype)initFromRemote:(NSDictionary *)publicKeyDictionary {
    self = [super initWithUniqueId:publicKeyDictionary[@"id"]];
    
    if (self) {
        _publicKey = publicKeyDictionary[@"publicKey"];
        _algorithm = publicKeyDictionary[@"algorithm"];
    }
    
    return self;
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
    NSMutableDictionary *keyPairDictionary = [[NSMutableDictionary alloc] init];
    if(self.uniqueId) [keyPairDictionary addEntriesFromDictionary:@{@"uniqueId" : self.uniqueId}];
    if(self.algorithm) [keyPairDictionary addEntriesFromDictionary:@{@"algorithm" : self.algorithm}];
    if(self.publicKey) [keyPairDictionary addEntriesFromDictionary:@{@"publicKey" : self.publicKey}];
    return keyPairDictionary;
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
