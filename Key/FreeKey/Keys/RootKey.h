//
//  RootKey.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KDatabaseObject.h"

@class ECKeyPair;
@class RootChainPair;
@class ChainKey;

@interface RootKey : KDatabaseObject

@property (nonatomic, readonly) NSData *keyData;

- (instancetype)initWithData:(NSData *)data;

@end
