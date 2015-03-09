//
//  ChainKey.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MessageKey;

@interface ChainKey : NSObject

@property (nonatomic, readonly) int index;
@property (nonatomic, readonly) NSData *keyData;
@property (nonatomic, readonly) MessageKey *messageKey;

- (instancetype)initWithData:(NSData*)chainKey index:(int)index;
- (instancetype)nextChainKey;
- (NSData*)baseMaterial:(NSData*)seed;

@end
