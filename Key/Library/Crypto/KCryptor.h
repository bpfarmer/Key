//
//  KCryptor.h
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>


@class KError;

@interface KCryptor : NSObject

- (NSString *)encrypt:(NSString *)plainText
                  key:(NSString *)key
                error:(KError *)error;

- (NSString *)decrypt:(NSString *)cipherText
                  key:(NSString *)key
                error:(KError *)error;

- (NSDictionary *)encryptOneWay:(NSString *)text;

@end