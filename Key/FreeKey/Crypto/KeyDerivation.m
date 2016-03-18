//
//  KeyDerivation.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KeyDerivation.h"
#import "HKDFKit.h"

@implementation KeyDerivation

- (instancetype)derivedSecretsWithSeed:(NSData*)masterKey salt:(NSData*)salt {
    if (!salt) {
        const char *HKDFDefaultSalt[4] = {0};
        salt                           = [NSData dataWithBytes:HKDFDefaultSalt length:sizeof(HKDFDefaultSalt)];
    }
    
    NSData *info = [@"FreeKey" dataUsingEncoding:NSUTF8StringEncoding];
    
    @try {
        NSData *derivedMaterial = [HKDFKit deriveKey:masterKey info:info salt:salt outputSize:96];
        
        _cipherKey = [derivedMaterial subdataWithRange:NSMakeRange(0, 32)];
        _macKey    = [derivedMaterial subdataWithRange:NSMakeRange(32, 32)];
        _iv        = [derivedMaterial subdataWithRange:NSMakeRange(64, 16)];
    }
    @catch (NSException *exception) {
        @throw NSInvalidArgumentException;
    }
    
    return self;
}

- (instancetype)fromMasterKey:(NSData*)masterKey{
    return [self derivedSecretsWithSeed:masterKey salt:nil];
}

- (instancetype)fromSharedSecret:(NSData*)masterKey rootKey:(NSData*)rootKey{
    return [self derivedSecretsWithSeed:masterKey salt:rootKey];
}

- (instancetype)fromData:(NSData*)data{
    return [self derivedSecretsWithSeed:data salt:nil];
}
@end
