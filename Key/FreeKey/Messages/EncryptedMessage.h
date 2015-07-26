//
//  EncryptedMessage.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSendable.h"
#import "KDatabaseObject.h"

@interface EncryptedMessage : KDatabaseObject <KSendable>

@property (nonatomic, readwrite) NSString *senderId;
@property (nonatomic, readwrite) NSString *receiverId;
@property (nonatomic, readonly) NSData *serializedData;
@property (nonatomic, readonly) NSData *senderRatchetKey;
@property (nonatomic, readonly) NSNumber *index;
@property (nonatomic, readonly) NSNumber *previousIndex;

- (instancetype)initWithSenderId:(NSString *)senderId
                      receiverId:(NSString *)receiverId
                  serializedData:(NSData *)serializedData
                senderRatchetKey:(NSData *)senderRatchetKey
                           index:(NSNumber *)index
                   previousIndex:(NSNumber *)previousIndex;

@end
