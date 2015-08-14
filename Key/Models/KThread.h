//
//  KThread.h
//  Key
//
//  Created by Brendan Farmer on 2/5/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KDatabaseObject.h"
#import "KEncryptable.h"

@class KMessage;

@interface KThread : KDatabaseObject <KEncryptable>

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *userIds;
@property (nonatomic) NSString *latestMessageId;
@property (nonatomic) BOOL read;
//@property (nonatomic) NSDate *lastMessageAt;
//@property (nonatomic) NSDate *archivedAt;

- (instancetype)initWithUsers:(NSArray *)user;
- (instancetype)initWithUniqueId:(NSString *)uniqueId
                         userIds:(NSString *)userIds
                            name:(NSString *)name
                 latestMessageId:(NSString *)latestMessageId
                            read:(BOOL)read;

- (void)processLatestMessage:(KMessage *)message;
- (NSArray *)recipientIds;
- (NSArray *)messages;
- (NSString *)displayName;
- (BOOL)saved;
- (KMessage *)latestMessage;

@end
