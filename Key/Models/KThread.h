//
//  KThread.h
//  Key
//
//  Created by Brendan Farmer on 2/5/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YapDatabase/YapDatabaseRelationshipNode.h>
#import "KYapDatabaseObject.h"
#import "KEncryptable.h"

@class KMessage;

@interface KThread : KYapDatabaseObject <YapDatabaseRelationshipNode, KEncryptable>

@property (nonatomic) NSString *name;
@property (nonatomic) NSArray *userIds;
@property (nonatomic) KMessage *latestMessage;
@property (nonatomic) BOOL read;
@property (nonatomic) NSDate *lastMessageAt;
@property (nonatomic) NSDate *archivedAt;

- (instancetype)initWithUsers:(NSArray *)user;
- (instancetype)initFromRemote:(NSDictionary *)threadDictionary;
- (instancetype)initWithUniqueId:(NSString *)uniqueId
                         userIds:(NSArray *)userIds
                            name:(NSString *)name
                   latestMessage:(KMessage *)latestMessage
                   lastMessageAt:(NSDate *)lastMessageAt
                      archivedAt:(NSDate *)archivedAt
                            read:(BOOL)read;

- (NSString *)displayName;
- (void)processLatestMessage:(KMessage *)message;
- (NSArray *)recipientIds;

@end
