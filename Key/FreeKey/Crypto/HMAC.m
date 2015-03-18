//
//  HMAC.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/7/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HMAC.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation HMAC

+ (NSData*)generateMacWithMacKey:(NSData *)macKey
               senderIdentityKey:(NSData *)senderIdentityKey
             receiverIdentityKey:(NSData *)receiverIdentityKey
                  serializedData:(NSData *)serializedData {
    
    uint8_t ourHmac[CC_SHA256_DIGEST_LENGTH] = {0};
    CCHmacContext context;
    CCHmacInit  (&context, kCCHmacAlgSHA256, [macKey bytes], [macKey length]);
    CCHmacUpdate(&context, [senderIdentityKey bytes], [senderIdentityKey length]);
    CCHmacUpdate(&context, [receiverIdentityKey bytes], [receiverIdentityKey length]);
    CCHmacUpdate(&context, [serializedData bytes], [serializedData length]);
    CCHmacFinal (&context, &ourHmac);
    
    return [NSData dataWithBytes:ourHmac length:8];
}

+ (BOOL)verifyWithMac:(NSData *)mac
    senderIdentityKey:(NSData *)senderIdentityKey
  receiverIdentityKey:(NSData*)receiverIdentityKey
               macKey:(NSData *)macKey
       serializedData:(NSData *)serializedData {
    
    NSData *data     = [serializedData subdataWithRange:NSMakeRange(0, serializedData.length - 8)];
    NSData *theirMac = [serializedData subdataWithRange:NSMakeRange(serializedData.length - 8, 8)];
    NSData *ourMac   = [self generateMacWithMacKey:macKey
                                 senderIdentityKey:senderIdentityKey
                               receiverIdentityKey:receiverIdentityKey
                                    serializedData:data];
    
    if (![theirMac isEqualToData:ourMac]) {
        //@throw [NSException exceptionWithName:InvalidMessageException reason:@"Bad Mac!" userInfo:@{}];
        return NO;
    }
    return YES;
}

@end
