//
//  ChainKey.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ChainKey.h"
#import "KeyDerivation.h"
#import "MessageKey.h"
#import <CommonCrypto/CommonCrypto.h>
#import "ChainKey+Serialize.h"

@implementation ChainKey

#define kTSKeySeedLength 1

static uint8_t kMessageKeySeed[kTSKeySeedLength]    = {01};
static uint8_t kChainKeySeed[kTSKeySeedLength]      = {02};


-(instancetype)initWithData:(NSData *)chainKey index:(int)index{
    self = [super init];
    
    if (self) {
        _keyData   = chainKey;
        _index = index;
        KeyDerivation *keyMaterial = [[KeyDerivation alloc] fromData:[self baseMaterial:[NSData dataWithBytes:kMessageKeySeed length:kTSKeySeedLength]]];
        _messageKey = [[MessageKey alloc] initWithCipherKey:keyMaterial.cipherKey
                                                     macKey:keyMaterial.macKey
                                                         iv:keyMaterial.iv
                                                      index:self.index];
    }
    
    return self;
}

- (instancetype) nextChainKey{
    NSData* nextCK = [self baseMaterial:[NSData dataWithBytes:kChainKeySeed length:kTSKeySeedLength]];
    return [[ChainKey alloc] initWithData:nextCK index:self.index+1];
}

- (NSData*)baseMaterial:(NSData*)seed{
    uint8_t result[CC_SHA256_DIGEST_LENGTH] = {0};
    CCHmacContext ctx;
    CCHmacInit(&ctx, kCCHmacAlgSHA256, [self.keyData bytes], [self.keyData length]);
    CCHmacUpdate(&ctx, [seed bytes], [seed length]);
    CCHmacFinal(&ctx, result);
    return [NSData dataWithBytes:result length:sizeof(result)];
}


@end
