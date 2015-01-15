//
//  KRSACryptor.h
//  Key
//
//  Created by Brendan Farmer on 1/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCryptor.h"
#import "KRSACryptorKeyPair.h"

@class KRSACryptorKeyPair;

@interface KRSACryptor : KCryptor


/**
 This method will parse a PEM formatted RSA private key and place it on the keychain.
 
 The key loaded in the constructed should be a PEM formatted private key string.
 
 @param tag A unique tag to identify the key on the keychain for later use.
 @param key The key to add to the keychain.
 @param error Will be populated with an appropriate error message in the event of a parsing or addition failure.
 
 @return YES if no error, NO otherwise.
 */
- (void)setPrivateKey:(NSString *)key
                  tag:(NSString *)tag
                error:(KError *)error;

/**
 This method will parse a PEM formatted RSA public key and place it on the keychain.
 
 The key loaded in the constructed should be a PEM formatted public key string.
 
 @param tag A unique tag to identify the key on the keychain for later use.
 @param key The key to add to the keychain.
 @param error Will be populated with an appropriate error message in the event of a parsing or addition failure.
 
 @return YES if no error, NO otherwise.
 */
- (void)setPublicKey:(NSString *)key
                 tag:(NSString *)tag
               error:(KError *)error;

/**
 This method will remove a key with a given tag from the keychain.
 
 @param tag A unique tag to identify the key on the keychain for later use.
 @param error Will be populated with an appropriate error message in the event of an decryption failure.
 
 @return YES if no error, NO otherwise.
 */
- (void)removeKey:(NSString *)tag
            error:(KError *)error;

/**
 This method will retrieve a public key from the keychain and return the X509 PEM formatted representation of the key.
 
 @param tag A unique tag to identify the public key on the keychain for later use.
 @param error Will be populated with an appropriate error message in the event of an decryption failure.
 
 @return An X509 PEM formatted public key.
 */
- (NSString *)X509FormattedPublicKey:(NSString *)tag
                               error:(KError *)error;

/**
 This method will retrieve a private key from the keychain and return the X509 PEM formatted representation of the key.
 
 @param tag A unique tag to identify the public key on the keychain for later use.
 @param error Will be populated with an appropriate error message in the event of an decryption failure.
 @return An PEM formatted private key.
 */
- (NSString *)PEMFormattedPrivateKey:(NSString *)tag
                               error:(KError *)error;

- (NSString *)publicKeyIdentifierWithTag:(NSString *)additionalTag;
- (NSString *)privateKeyIdentifierWithTag:(NSString *)additionalTag;

- (KRSACryptorKeyPair *)generateKeyPairWithKeyIdentifier:(NSString *)keyIdentifier
                                                  error:(KError *)error;

@end
