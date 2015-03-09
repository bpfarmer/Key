//
//  AES_CBC.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/2/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AES_CBC : NSObject

/**
 *  Encrypts with AES in CBC mode
 *
 *  @param data     data to encrypt
 *  @param key      AES key
 *  @param iv       Initialization vector for CBC
 *
 *  @return         ciphertext
 */

+(NSData*)encryptCBCMode:(NSData*)data withKey:(NSData*)key withIV:(NSData*)iv;

/**
 *  Decrypts with AES in CBC mode
 *
 *  @param data     data to decrypt
 *  @param key      AES key
 *  @param iv       Initialization vector for CBC
 *
 *  @return         plaintext
 */

+(NSData*)decryptCBCMode:(NSData*)data withKey:(NSData*)key withIV:(NSData*)iv;


@end
