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
#import "KObjectRecipient.h"
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
        for(NSString *userId in self.userIds) [KUser asyncFindById:userId];
    }
    return self;
}

- (instancetype)initWithUniqueId:(NSString *)uniqueId {
    NSArray *components = [uniqueId componentsSeparatedByString:@"_"];
    if(components.count > 1) return [self initWithUserIds:[components subarrayWithRange:NSMakeRange(1, components.count - 1)]];
    else return [super initWithUniqueId:uniqueId];
}

- (void)save {
    if(!self.uniqueId) return;
    [super save];
}

- (void)addRecipients:(NSArray *)recipients {
    NSMutableArray *recipientIds  = [NSMutableArray new];
    for(KDatabaseObject *recipient in recipients) if(![recipientIds containsObject:recipient.uniqueId]) [recipientIds addObject:recipient.uniqueId];
    [self addRecipientIds:[recipientIds copy]];
}

- (void)addRecipientIds:(NSArray *)recipientIds {
    NSMutableArray *userIds    = [NSMutableArray arrayWithArray:self.recipientIds];
    for(NSString *recipientId in recipientIds) if(![userIds containsObject:recipientId]) [userIds addObject:recipientId];
    NSMutableArray *usernames  = [NSMutableArray new];
    [userIds sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    for(NSString *recipientId in userIds) {
        KUser *user =[ KUser findById:recipientId];
        if(user)[usernames addObject:user.username];
        else [[KUser asyncFindById:recipientId] thenDo:^(KUser *newUser) {
            [self updateNameWithUser:newUser];
        }];
    }
    self.uniqueId = [KThread uniqueIdFromUserIds:userIds];
    self.name     = [usernames componentsJoinedByString:@", "];
}

- (void)updateNameWithUser:(KUser *)user {
    NSMutableArray *nameComponents = [NSMutableArray arrayWithArray:[self.name componentsSeparatedByString:@", "]];
    if(![nameComponents containsObject:user.username]) [nameComponents addObject:user.username];
    self.name = [nameComponents componentsJoinedByString:@", "];
    [self save];
}

+ (NSString *)uniqueIdFromUserIds:(NSArray *)userIds {
    return [NSString stringWithFormat:@"%@_%@", NSStringFromClass([KThread class]), [userIds componentsJoinedByString:@"_"]];
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
    
    if([self isMostRecentMessage:message]) {
        self.updatedAt       = message.createdAt;
        self.latestMessageId = message.uniqueId;
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

- (NSArray *)userIds {
    NSArray *components = [self.uniqueId componentsSeparatedByString:@"_"];
    if(components.count > 1) return [components subarrayWithRange:NSMakeRange(1, components.count - 1)];
    return nil;
}

- (NSArray *)recipientIds {
    KUser *localUser = [KAccountManager sharedManager].user;
    NSMutableArray *recipientIds = [NSMutableArray arrayWithArray:self.userIds];
    [recipientIds removeObject:localUser.uniqueId];
    return [recipientIds copy];
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
    NSArray *objectRecipients = @[];
    NSMutableArray *threadAndPostIds = [NSMutableArray arrayWithObject:self.uniqueId];
    NSMutableArray *questionMarks = [NSMutableArray new];
    if(self.recipientIds.count == 1) objectRecipients = [KObjectRecipient findAllByDictionary:@{@"recipientId" : self.recipientIds.firstObject}];
    for(KObjectRecipient *or in objectRecipients) {
        [threadAndPostIds addObject:or.objectId];
        [questionMarks addObject:@"?"];
    }
    NSLog(@"PARAMETERS: %@", threadAndPostIds);
    NSString *selectSQL = [NSString stringWithFormat:@"select * from %@ where thread_id = :thread_id or unique_id in (%@)", [KPost tableName], [questionMarks componentsJoinedByString:@" , "]];
    return [[KStorageManager sharedManager] querySelectObjects:^NSArray *(FMDatabase *database) {
        FMResultSet *result =  [database executeQuery:selectSQL withArgumentsInArray:threadAndPostIds];
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