//
//  KCryptor.m
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KCryptor.h"
#import <CommonCrypto/CommonKeyDerivation.h>
#import "Util.h"

@implementation KCryptor


- (NSString *)encrypt:(NSString *)plainText
                  key:(NSString *)key
                error:(KError *)error
{
    return nil;
}


- (NSString *)decrypt:(NSString *)cipherText
                  key:(NSString *)key
                error:(KError *)error
{
    return nil;
}

- (NSDictionary *)encryptOneWay:(NSString *)text {
    
    NSData* textData = [text dataUsingEncoding:NSUTF8StringEncoding];
    NSInteger saltLength = 128;
    NSData* salt = [Util generateRandomString:saltLength];
    
    int rounds = CCCalibratePBKDF(kCCPBKDF2, textData.length, salt.length, kCCPRFHmacAlgSHA256, saltLength, 100);
    unsigned char key[(size_t)saltLength];
    CCKeyDerivationPBKDF(kCCPBKDF2, textData.bytes, textData.length, salt.bytes, salt.length, kCCPRFHmacAlgSHA256, rounds, key, saltLength);

    return @{@"encrypted" : [NSData dataWithBytes:key length:sizeof(key)], @"salt" : salt};
}

+(NSData*)generateSecureRandomData:(NSUInteger)length {
    NSMutableData* d = [NSMutableData dataWithLength:length];
    SecRandomCopyBytes(kSecRandomDefault, length, [d mutableBytes]);
    return d;
}
@end