//
//  SessionState.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/7/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KDatabaseObject.h"

@class MessageKey;

@interface SessionState : KDatabaseObject

@property (nonatomic, readonly) NSData *cipherKey;
@property (nonatomic, readonly) NSData *iv;
@property (nonatomic, readonly) NSData *macKey;
@property (nonatomic, readonly) NSData *senderRatchetKey;
@property (nonatomic, readonly) NSNumber *messageIndex;
@property (nonatomic, readonly) NSString *sessionId;

- (instancetype)initWithMessageKey:(MessageKey *)messageKey senderRatchetKey:(NSData *)senderRatchetKey messageIndex:(NSNumber *)messageIndex sessionId:(NSString *)sessionId;

- (MessageKey *)messageKey;

@end
