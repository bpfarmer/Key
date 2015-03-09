//
//  MasterKey.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "MasterKey.h"
#import <25519/Curve25519.h>
#import <25519/Ed25519.h>
#import "SessionKeyBundle.h"
#import "PreKey.h"
#import "IdentityKey.h"

@implementation MasterKey

- (instancetype) initFromKeyBundle:(SessionKeyBundle *)keyBundle {
    self = [super init];
    
    if(self) {
        NSMutableData *masterKey = [[NSMutableData alloc] init];
        
        if(keyBundle.isAlice) {
            [masterKey appendData:
                    [Curve25519 generateSharedSecretFromPublicKey:keyBundle.theirBaseKey andKeyPair:keyBundle.ourIdentityKeyPair]];
            [masterKey appendData:
                    [Curve25519 generateSharedSecretFromPublicKey:keyBundle.theirIdentityKey andKeyPair:keyBundle.ourBaseKey]];
            [masterKey appendData:
                    [Curve25519 generateSharedSecretFromPublicKey:keyBundle.theirBaseKey andKeyPair:keyBundle.ourBaseKey]];
        }else {
            [masterKey appendData:
                    [Curve25519 generateSharedSecretFromPublicKey:keyBundle.theirIdentityKey andKeyPair:keyBundle.ourBaseKey]];
            [masterKey appendData:
                    [Curve25519 generateSharedSecretFromPublicKey:keyBundle.theirBaseKey andKeyPair:keyBundle.ourIdentityKeyPair]];
            [masterKey appendData:
                    [Curve25519 generateSharedSecretFromPublicKey:keyBundle.theirBaseKey andKeyPair:keyBundle.ourBaseKey]];
        }
        _keyData = masterKey;
    }
    
    return self;
}

@end
