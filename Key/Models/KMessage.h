//
//  KMessage.h
//  Key
//
//  Created by Brendan Farmer on 1/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <YapDatabase/YapDatabaseRelationshipNode.h>
#import "KYapDatabaseObject.h"

@class KUser;
@class KGroup;
@class KMessageCrypt;
@class KThread;

@interface KMessage : KYapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic) NSString *authorId;
@property (nonatomic) NSString *threadId;
@property (nonatomic) NSString *body;
@property (nonatomic) NSString *sendStatus;
@property (nonatomic) BOOL read;
@property (nonatomic) NSDate *createdAt;

- (instancetype)initFromAuthorId:(NSString *)authorId threadId:(NSString *)threadId body:(NSString *)body;
- (void)sendToRecipients;

@end
