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
#import "KThreadable.h"

@class KMessage;

@interface KThread : KDatabaseObject <KEncryptable>

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *userIds;
@property (nonatomic) NSString *latestMessageId;
@property (nonatomic) BOOL read;
@property (nonatomic) NSDate *updatedAt;

- (instancetype)initWithUsers:(NSArray *)user;
- (instancetype)initWithUniqueId:(NSString *)uniqueId
                         userIds:(NSString *)userIds
                            name:(NSString *)name
                 latestMessageId:(NSString *)latestMessageId
                            read:(BOOL)read;

- (void)processLatestMessage:(KDatabaseObject <KThreadable> *)message;
- (NSArray *)recipientIds;
//+ (NSArray *)inbox;
- (NSArray *)messages;
- (NSArray *)posts;
- (NSString *)displayName;
- (BOOL)saved;
- (KMessage *)latestMessage;
- (NSString *)latestMessageText;
+ (KThread *)findWithUserIds:(NSArray *)userIds;
- (BOOL)isMoreRecentThan:(KThread *)thread;

@end
