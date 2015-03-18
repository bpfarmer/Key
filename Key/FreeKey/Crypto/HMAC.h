//
//  HMAC.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/7/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMAC : NSObject

+ (NSData*)generateMacWithMacKey:(NSData *)macKey
               senderIdentityKey:(NSData *)senderIdentityKey
             receiverIdentityKey:(NSData *)receiverIdentityKey
                  serializedData:(NSData *)serializedData;

+ (BOOL)verifyWithMac:(NSData *)mac
    senderIdentityKey:(NSData *)senderIdentityKey
  receiverIdentityKey:(NSData*)receiverIdentityKey
               macKey:(NSData *)macKey
       serializedData:(NSData *)serializedData;

@end
