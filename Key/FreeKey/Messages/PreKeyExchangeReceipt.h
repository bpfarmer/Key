//
//  PreKeyExchangeReceipt.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/7/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KDatabaseObject.h"

@interface PreKeyExchangeReceipt : KDatabaseObject

@property (nonatomic, readonly) NSString *senderId;
@property (nonatomic, readonly) NSString *receiverId;
@property (nonatomic, readonly) NSData   *receivedBasePublicKey;

- (instancetype)initFromSenderId:(NSString *)senderId receiverId:(NSString *)receiverId receivedBasePublicKey:(NSData *)receivedBasePublicKey;

@end
