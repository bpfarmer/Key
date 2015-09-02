//
//  KThread.m
//  Key
//
//  Created by Brendan Farmer on 2/5/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KThread.h"
#import "Util.h"
#import "KUser.h"
#import "KStorageManager.h"
#import "FreeKey.h"
#import "KAccountManager.h"
#import "KMessage.h"
#import "KPost.h"
#import "ObjectRecipient.h"
#import "CollapsingFutures.h"

@implementation KThread

- (instancetype)initWithUsers:(NSArray *)users {
    [self addRecipients:users];
    if([KThread findById:self.uniqueId]) return [KThread findById:self.uniqueId];
    return self;
}

- (instancetype)initWithUserIds:(NSArray *)userIds {
    [self addRecipientIds:userIds];
    if([KThread findById:self.uniqueId]) return [KThread findById:self.uniqueId];
    return self;
}

- (instancetype)initWithUniqueId:(NSString *)uniqueId name:(NSString *)name latestMessageId:(NSString *)latestMessageId read:(BOOL)read {
    self = [super initWithUniqueId:uniqueId];
    if (self) {
        _name               = name;
        _latestMessageId    = latestMessageId;
        _read               = read;
    }
    return self;
}

- (void)save {
    if(!self.name || !self.uniqueId) return;
    [super save];
}

- (void)addRecipients:(NSArray *)recipients {
    NSMutableArray *recipientIds  = [NSMutableArray new];
    for(KDatabaseObject *recipient in recipients) [recipientIds addObject:recipient.uniqueId];
    [self addRecipientIds:[recipientIds copy]];
}

- (void)addRecipientIds:(NSArray *)recipientIds {
    NSMutableArray *userIds    = [NSMutableArray arrayWithArray:recipientIds];
    NSMutableArray *usernames  = [NSMutableArray new];
    
    [userIds sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    
    for(NSString *recipientId in userIds) [usernames addObject:[KUser findById:recipientId].username];
    
    self.uniqueId = [userIds componentsJoinedByString:@"_"];
    self.name     = [usernames componentsJoinedByString:@", "];
}

- (void)sendWithAttachableObjects:(NSArray *)attachableObjects {
    return;
}

- (void)processLatestMessage:(KDatabaseObject <KThreadable> *)message {
    KUser *currentUser = [KAccountManager sharedManager].user;
    if(![message.authorId isEqualToString:currentUser.uniqueId]) {
        self.read = NO;
    }else {
        self.read = YES;
    }
    
    if(!self.updatedAt) self.updatedAt = [NSDate dateWithTimeIntervalSince1970:0];
    
    NSLog(@"UPDATED AT: %@", self.updatedAt);
    
    if([self isMostRecentMessage:message]) {
        NSLog(@"CORRECTLY DETERMINED LATEST MESSAGE");
        self.updatedAt       = message.createdAt;
        self.latestMessageId = message.uniqueId;
        NSLog(@"LATEST MESSAGE ID: %@", self.latestMessageId);
        [self save];
    }
}

- (BOOL)isMostRecentMessage:(KDatabaseObject <KThreadable> *)newMessage {
    NSComparisonResult dateComparison = [newMessage.createdAt compare:self.updatedAt];
    switch (dateComparison) {
        case NSOrderedDescending : return YES; break;
        default : return NO; break;
    }
}

- (BOOL)isMoreRecentThan:(KThread *)thread {
    NSComparisonResult dateComparison = [self.updatedAt compare:thread.updatedAt];
    switch (dateComparison) {
        case NSOrderedDescending : return YES; break;
        default : return NO; break;
    }
}

- (NSString *)displayName {
    NSMutableArray *names = [[NSMutableArray alloc] initWithArray:[self.name componentsSeparatedByString:@", "]];
    [names removeObject:[KAccountManager sharedManager].user.username];
    return [names componentsJoinedByString:@", "];
}

- (NSString *)userIds {
    return self.uniqueId;
}

- (NSArray *)recipientIds {
    KUser *localUser = [KAccountManager sharedManager].user;
    NSMutableArray *recipientIds = [NSMutableArray arrayWithArray:[self.userIds componentsSeparatedByString:@"_"]];
    [recipientIds removeObject:localUser.uniqueId];
    return [recipientIds copy];
}

+ (NSArray *)inbox {
    NSString *inboxSQL = [NSString stringWithFormat:@"select * from %@ order by updated_at desc", [KThread tableName]];
    
    return [[KStorageManager sharedManager] querySelectObjects:^NSArray *(FMDatabase *database) {
        FMResultSet *result =  [database executeQuery:inboxSQL];
        NSMutableArray *threads = [[NSMutableArray alloc] init];
        while(result.next) [threads addObject:[[KThread alloc] initWithResultSetRow:result.resultDictionary]];
        [result close];
        return [threads copy];
    }];
}

+ (KThread *)findWithUserIds:(NSArray *)userIds {
    NSMutableArray *sortableUserIds = [NSMutableArray arrayWithArray:userIds];
    [sortableUserIds sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    
    return [self findById:[sortableUserIds componentsJoinedByString:@"_"]];
}

- (NSArray *)messages {
    return [KMessage findAllByDictionary:@{@"threadId" : self.uniqueId} orderBy:@"createdAt" descending:NO];
}

- (NSArray *)posts {
    NSArray *objectRecipients = [ObjectRecipient findAllByDictionary:@{@"recipientId" : self.recipientIds.firstObject}];
    NSMutableArray *postIds = [NSMutableArray arrayWithObject:self.uniqueId];
    NSMutableArray *questionMarks = [NSMutableArray new];
    for(ObjectRecipient *or in objectRecipients) {
        [postIds addObject:or.objectId];
        [questionMarks addObject:@"?"];
    }
    NSString *selectSQL = [NSString stringWithFormat:@"select * from %@ where thread_id = :thread_id or unique_id in (%@)", [KPost tableName], [questionMarks componentsJoinedByString:@" , "]];
    return [[KStorageManager sharedManager] querySelectObjects:^NSArray *(FMDatabase *database) {
        FMResultSet *result =  [database executeQuery:selectSQL withArgumentsInArray:postIds];
        NSMutableArray *posts = [[NSMutableArray alloc] init];
        while(result.next) [posts addObject:[[KPost alloc] initWithResultSetRow:result.resultDictionary]];
        [result close];
        return [posts copy];
    }];
}

- (NSString *)latestMessageText {
    if(!self.latestMessageId) return @"";
    KDatabaseObject <KThreadable> *message = self.latestMessage;
    if([message isKindOfClass:[KPost class]]) return @"New Photo";
    else return ((KMessage *)message).text;
}

- (KDatabaseObject <KThreadable> *)latestMessage {
    NSArray *latestMessageComponents = [self.latestMessageId componentsSeparatedByString:@"_"];
    return [NSClassFromString(latestMessageComponents.firstObject) findById:self.latestMessageId];
}

- (BOOL)saved {
    return ([KThread findById:self.uniqueId] != nil);
}
@end