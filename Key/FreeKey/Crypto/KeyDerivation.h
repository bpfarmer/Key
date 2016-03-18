//
//  KeyDerivation.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyDerivation : NSObject

@property (nonatomic, readonly) NSData *cipherKey;
@property (nonatomic, readonly) NSData *macKey;
@property (nonatomic, readonly) NSData *iv;

- (instancetype)fromMasterKey:(NSData*)masterKey;
- (instancetype)fromSharedSecret:(NSData*)masterKey rootKey:(NSData*)rootKey;
- (instancetype)fromData:(NSData*)data;

@end
