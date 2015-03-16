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
        _serializedData   = cipherText;
        _index            = index;
        _previousIndex    = previousIndex;
    }
    return self;
}

- (instancetype)initWithSenderRatchetKey:(NSData *)senderRatchetKey
                              receiverId:(NSString *)receiverId
                          serializedData:(NSData *)serializedData
                                   index:(int)index
                           previousIndex:(int)previousIndex {
    self = [super init];
    
    if(self) {
        _senderRatchetKey = senderRatchetKey;
        _receiverId       = receiverId;
        _serializedData   = serializedData;
        _cipherText       = [serializedData subdataWithRange:NSMakeRange(0, serializedData.length - 8)];
        _index            = index;
        _previousIndex    = previousIndex;
    }
    return self;
}

// TODO: use MAC generation here
// TODO: check MAC
- (void)setMac {
    NSMutableData *serializedWithMac = [[NSMutableData alloc] initWithBase64EncodedData:self.serializedData options:0];
    for( unsigned int i = 0 ; i < 2 ; ++i )
    {
        u_int32_t randomBits = arc4random();
        [serializedWithMac appendBytes:(void*)&randomBits length:4];
    }
    _serializedData = serializedWithMac;
}

- (NSArray *)keysToSend {
    return @[@"senderRatchetKey", @"receiverId", @"serializedData", @"index", @"previousIndex"];
}

@end
