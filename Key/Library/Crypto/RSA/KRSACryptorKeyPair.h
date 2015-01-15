//
//  RSACryptorKeyPair.h
//  key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KRSACryptorKeyPair : NSObject

@property (nonatomic, strong) NSString *publicKey;
@property (nonatomic, strong) NSString *privateKey;

- (id)initWithPublicKey:(NSString *)publicKey
             privateKey:(NSString *)privateKey;

@end