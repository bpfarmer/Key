//
//  RootKey.m
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "RootKey.h"
#import "ChainKey.h"
#import "RootChain.h"
#import "RootKey+Serialize.h"

@implementation RootKey

- (instancetype)initWithData:(NSData *)data{
    self = [super init];
    
    if (self) {
        _keyData = data;
    }
    
    return self;
}

@end
