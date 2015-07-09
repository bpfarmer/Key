//
//  MessageKey.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KDatabaseObject.h"

@interface MessageKey : NSObject

@property (nonatomic, readonly) NSData *cipherKey;
@property (nonatomic, readonly) NSData *macKey;
@property (nonatomic, readonly) NSData *iv;
@property (nonatomic, readonly) int index;

- (instancetype)initWithCipherKey:(NSData*)cipherKey macKey:(NSData*)macKey iv:(NSData*)iv index:(int)index;

@end
