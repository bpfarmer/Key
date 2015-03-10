//
//  RootKey.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECKeyPair;
@class RootChainPair;
@class ChainKey;

@interface RootKey : NSObject

@property (nonatomic, readonly) NSData *keyData;

- (instancetype)initWithData:(NSData *)data;

@end