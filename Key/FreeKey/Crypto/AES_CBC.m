//
//  AES_CBC.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/2/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "AES_CBC.h"
#import "FreeKeyExceptions.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonCryptor.h>

@implementation AES_CBC

#pragma mark AESCBC Mode

+(NSData*)encryptCBCMode:(NSData*)data withKey:(NSData*)key withIV:(NSData*)iv{
    NSAssert(data, @"Missing data to encrypt");
    NSAssert([key length] == 32, @"AES key should be 256 bits");
    NSAssert([iv  length] == 16, @"AES-CBC IV should be 128 bits");
    
    size_t bufferSize           = [data length] + kCCBlockSizeAES128;
    void* buffer                = malloc(bufferSize);
    
    size_t bytesEncrypted    = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          [key bytes], [key length],
                                          [iv bytes],
                                          [data bytes], [data length],
                                          buffer, bufferSize,
                                          &bytesEncrypted);
    
    if (cryptStatus == kCCSuccess){
        return [NSData dataWithBytesNoCopy:buffer length:bytesEncrypted];
    } else{
        free(buffer);
        @throw [NSException exceptionWithName:CipherException reason:@"We encountered an issue while encrypting." userInfo:nil];
    }
}

+(NSData*) decryptCBCMode:(NSData*)data withKey:(NSData*)key withIV:(NSData*)iv {
    
    size_t bufferSize           = [data length] + kCCBlockSizeAES128;
    void* buffer                = malloc(bufferSize);
    
    size_t bytesDecrypted    = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          [key bytes], [key length],
                                          [iv bytes],
                                          [data bytes], [data length],
                                          buffer, bufferSize,
                                          &bytesDecrypted);
    
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:bytesDecrypted];
    } else{
        free(buffer);
        @throw [NSException exceptionWithName:CipherException reason:@"We encountered an issue while decrypting." userInfo:nil];
    }
}

@end
