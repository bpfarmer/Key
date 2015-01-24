//
//  KKeyPair.h
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Realm/Realm.h>

@class KUser;

@interface KKeyPair : RLMObject

@property NSString *publicId;
@property NSString *privateKey;
@property NSString *publicKey;
@property NSString *algorithm;

+ (KKeyPair *)createRSAKeyPair;
- (NSString *)encryptText:(NSString *)text;
- (NSString *)decryptText:(NSString *)textCrypt;
- (NSData *)encryptData:(NSData *)data;
- (NSData *)decryptData:(NSData *)dataCrypt;
- (NSDictionary *)toDictionary;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<KKeyPair>
RLM_ARRAY_TYPE(KKeyPair)
