//
//  NSData+keyVersionByte.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/3/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (keyVersionByte)

- (instancetype)prependKeyType;
- (instancetype)removeKeyType;

@end