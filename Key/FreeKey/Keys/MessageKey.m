//
//  MessageKey.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "MessageKey.h"

@implementation MessageKey

- (instancetype)initWithCipherKey:(NSData *)cipherKey macKey:(NSData *)macKey iv:(NSData *)iv index:(int)index {
    self = [super init];
    
    if(self) {
        _cipherKey = cipherKey;
        _macKey    = macKey;
        _iv        = iv;
        _index     = index;
    }
    return self;
}
@end
