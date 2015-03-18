//
//  PreKey.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/3/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "PreKey.h"
#import "PreKey+Serialize.h"

@implementation PreKey

- (instancetype)initWithUserId:(NSString *)userId
                      deviceId:(NSString *)deviceId
                signedPreKeyId:(NSString *)signedPreKeyId
            signedPreKeyPublic:(NSData *)signedPreKeyPublic
         signedPreKeySignature:(NSData *)signedPreKeySignature
                   identityKey:(NSData *)identityKey
                   baseKeyPair:(ECKeyPair *)baseKeyPair {
    
    self = [super init];
    
    if (self) {
        _identityKey           = identityKey;
        _userId                = userId;
        _deviceId              = deviceId;
        _signedPreKeyPublic    = signedPreKeyPublic;
        _signedPreKeyId        = signedPreKeyId;
        _signedPreKeySignature = signedPreKeySignature;
        _baseKeyPair           = baseKeyPair;
    }
    
    return self;
}

+ (NSArray *)remoteKeys {
    return @[@"userId", @"deviceId", @"signedPreKeyId", @"signedPreKeyPublic", @"signedPreKeySignature", @"identityKey"];
}

@end