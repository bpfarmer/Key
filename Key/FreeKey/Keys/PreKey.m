//
//  PreKey.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/3/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "PreKey.h"
#import "FreeKey.h"

@implementation PreKey

- (instancetype)initWithUniqueId:(NSString *)uniqueId userId:(NSString *)userId basePublicKey:(NSData *)basePublicKey signature:(NSData *)signature publicKey:(NSData *)publicKey baseKeyPair:(ECKeyPair *)baseKeyPair {
    self = [super initWithUniqueId:uniqueId];
    
    if (self) {
        _userId                = userId;
        _basePublicKey         = basePublicKey;
        _signature             = signature;
        _publicKey             = publicKey;
        _baseKeyPair           = baseKeyPair;
    }
    
    return self;
}

+ (NSArray *)remoteKeys {
    return @[@"uniqueId", @"userId", @"basePublicKey", @"signature", @"publicKey"];
}

+ (NSString *)remoteAlias {
    return kPreKeyRemoteAlias;
}

- (NSString *)remoteUserId {
    return [self.userId componentsSeparatedByString:@"_"].firstObject;
}

- (NSString *)remoteDeviceId {
    return self.userId;
}

@end