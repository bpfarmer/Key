//
//  KKeyPair.h
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <YapDatabase/YapDatabaseRelationshipNode.h>
#import "KYapDatabaseObject.h"

@class KUser;

@interface KKeyPair : KYapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic) NSString *privateKey;
@property (nonatomic) NSString *publicKey;
@property (nonatomic) NSString *algorithm;
@property (nonatomic) NSString *userId;

- (instancetype)initRSA;
- (instancetype)initFromRemote:(NSDictionary *)publicKeyDictionary;

- (NSDictionary *)toDictionary;

- (NSString *)encryptText:(NSString *)text;
- (NSString *)decryptText:(NSString *)textCrypt;
- (NSData *)encryptData:(NSData *)data;
- (NSData *)decryptData:(NSData *)dataCrypt;

- (NSDictionary *)toDictionary;

@end
