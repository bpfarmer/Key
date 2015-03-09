//
//  EncryptedMessage.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "EncryptedMessage.h"
#import <CommonCrypto/CommonCrypto.h>
#import "HMAC.h"

@implementation EncryptedMessage

- (instancetype)initWithMacKey:(NSData *)macKey
             senderIdentityKey:(NSData *)senderIdentityKey
           receiverIdentityKey:(NSData *)receiverIdentityKey
              senderRatchetKey:(NSData *)senderRatchetKey
                    cipherText:(NSData *)cipherText
                         index:(int)index
                 previousIndex:(int)previousIndex {
    
    
    self = [super init];
    
    if(self) {
        _senderRatchetKey = senderRatchetKey;
        _cipherText       = cipherText;
        _index            = index;
        _previousIndex    = previousIndex;
    }
    return self;
}

@end
