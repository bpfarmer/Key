//
//  SessionState.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/7/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MessageKey;

@interface SessionState : NSObject

@property (nonatomic, readonly) MessageKey *messageKey;
@property (nonatomic, readonly) NSData *senderRatchetKey;
@property (nonatomic, readonly) int index;

- (instancetype)initWithMessageKey:(MessageKey *)messageKey senderRatchetKey:(NSData *)senderRatchetKey index:(int)index;

@end
