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
#import "EncryptedMessage+Serialize.h"

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
        
        NSMutableData *messageAndMac = [[NSMutableData alloc] init];
        NSData *mac = [HMAC generateMacWithMacKey:macKey
                                senderIdentityKey:senderIdentityKey
                              receiverIdentityKey:receiverIdentityKey
                                   serializedData:cipherText];
        [messageAndMac appendData:cipherText];
        [messageAndMac appendData:mac];
        _mac              = mac;
        _serializedData   = messageAndMac;
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

+ (NSArray *)remoteKeys {
    return @[@"senderRatchetKey", @"receiverId", @"serializedData", @"index", @"previousIndex"];
}

@end
