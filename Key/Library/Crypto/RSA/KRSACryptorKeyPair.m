//
//  KRSACryptorKeyPair.m
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KRSACryptorKeyPair.h"

@implementation KRSACryptorKeyPair


- (id)initWithPublicKey:(NSString *)publicKey
             privateKey:(NSString *)privateKey
{
    self = [super init];
    
    if (self)
    {
        self.publicKey = publicKey;
        self.privateKey = privateKey;
    }
    
    return self;
}

@end