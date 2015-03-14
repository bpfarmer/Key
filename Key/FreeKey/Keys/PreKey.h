//
//  PreKey.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/3/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KYapDatabaseObject.h"

@class ECKeyPair;

@interface PreKey : NSObject
@property (nonatomic, readonly) NSString *userId;
@property (nonatomic, readonly) NSString *deviceId;
@property (nonatomic, readonly) NSString *signedPreKeyId;
@property (nonatomic, readonly) NSData   *signedPreKeyPublic;
@property (nonatomic, readonly) NSData   *signedPreKeySignature;
@property (nonatomic, readonly) NSData *identityKey;
@property (nonatomic, readonly) ECKeyPair *baseKeyPair;

- (instancetype)initWithUserId:(NSString *)userId
                      deviceId:(NSString *)deviceId
                signedPreKeyId:(NSString *)signedPreKeyId
            signedPreKeyPublic:(NSData*)signedPreKeyPublic
         signedPreKeySignature:(NSData*)signedPreKeySignature
                   identityKey:(NSData*)identityKey
                   baseKeyPair:(ECKeyPair *)baseKeyPair;

@end