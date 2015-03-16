//
//  EncryptedMessage.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EncryptedMessage : NSObject

@property (nonatomic, readonly) NSData *senderRatchetKey;
@property (nonatomic, readonly) int index;
@property (nonatomic, readonly) int previousIndex;
@property (nonatomic, readonly) NSData *cipherText;
@property (nonatomic, readonly) NSData *serializedData;

- (instancetype)initWithMacKey:(NSData *)macKey
             senderIdentityKey:(NSData *)senderIdentityKey
           receiverIdentityKey:(NSData *)receiverIdentityKey
              senderRatchetKey:(NSData *)senderRatchetKey
                    cipherText:(NSData *)cipherText
                         index:(int)index
                 previousIndex:(int)previousIndex;

- (instancetype) initWithSenderRatchetKey:(NSData *)senderRatchetKey
                           serializedData:(NSData *)serializedData
                                    index:(int)index
                            previousIndex:(int)previousIndex;


- (NSArray *)keysToSend;
@end
