//
//  KMessage.m
//  Key
//
//  Created by Brendan Farmer on 1/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//
#import "KMessage.h"
#import "KGroup.h"
#import "KMessageCrypt.h"
#import "KUser.h"
#import "KKeyPair.h"
#import "KThread.h"
#import "KStorageManager.h"

@implementation KMessage

- (NSArray *)yapDatabaseRelationshipEdges {
    NSArray *edges = nil;
    return edges;
}

- (instancetype)initFrom:(NSString *)userId threadId:(NSString *)threadId body:(NSString *)body {
    self = [super initWithUniqueId:nil];
    
    if (self) {
        _authorId = userId;
        _threadId = threadId;
        _body     = body;
    }
    return self;
}

- (void)sendMessages {
    KThread *thread = [[KStorageManager sharedManager] objectForKey:[self threadId] inCollection:[KThread collection]];
    
}

@end
