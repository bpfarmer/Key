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

@class KMessage;

@interface KThread : KYapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic) NSString *name;
@property (nonatomic) NSArray *userIds;
@property (nonatomic) KMessage *latestMessage;
@property (nonatomic) NSDate *lastMessageAt;
@property (nonatomic) NSDate *archivedAt;

- (instancetype)initWithUsers:(NSArray *)userIds;
- (instancetype)initFromRemote:(NSDictionary *)threadDictionary;

- (void)createAndSend;

@end
