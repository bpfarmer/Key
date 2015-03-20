//
//  EncryptedMessage.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSendable.h"

@interface EncryptedMessage : NSObject <KSendable>

@property (nonatomic, readonly) NSData *senderRatchetKey;
@property (nonatomic, readonly) int index;
@property (nonatomic, readonly) int previousIndex;
@property (nonatomic, readonly) NSData *cipherText;
@property (nonatomic, readonly) NSData *serializedData;
@property (nonatomic, readonly) NSData *mac;
@property (nonatomic, readwrite) NSString *senderId;
@property (nonatomic, readwrite) NSString *receiverId;
@property (nonatomic, readwrite) NSString *remoteStatus;

- (instancetype)initWithMacKey:(NSData *)macKey
             senderIdentityKey:(NSData *)senderIdentityKey
           receiverIdentityKey:(NSData *)receiverIdentityKey
              senderRatchetKey:(NSData *)senderRatchetKey
                    cipherText:(NSData *)cipherText
                         index:(int)index
                 previousIndex:(int)previousIndex;

- (instancetype) initWithSenderRatchetKey:(NSData *)senderRatchetKey
                                 senderId:(NSString *)senderId
                               receiverId:(NSString *)receiverId
                           serializedData:(NSData *)serializedData
                                    index:(int)index
                            previousIndex:(int)previousIndex;

+ (NSArray *)remoteKeys;
- (NSData *)mac;
- (void)addMetadataFromLocalUserId:(NSString *)localUser toRemoteUserId:(NSString *)remoteUserId;

@end
