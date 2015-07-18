//
//  KPost.m
//  Key
//
//  Created by Brendan Farmer on 4/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KPost.h"
#import "KUser.h"
#import "KStorageManager.h"
#import "Util.h"

@implementation KPost

- (KUser *)author {
    return [KUser findById:self.authorId];//[[KStorageManager sharedManager] objectForKey:self.authorId inCollection:[KUser collection]];
}

- (instancetype)initWithAuthorId:(NSString *)authorId text:(NSString *)text {
    self = [super init];
    
    if(self) {
        _authorId = authorId;
        _text     = text;
        _createdAt     = [NSDate date];
        [self setUniqueId:[self generateUniqueId]];
    }
    
    return self;
}

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                        authorId:(NSString *)authorId
                            text:(NSString *)text
                     attachments:(NSArray *)attachments
                            seen:(BOOL)seen
                       createdAt:(NSDate *)createdAt{
    self = [super initWithUniqueId:uniqueId];
    
    if(self) {
        _authorId     = authorId;
        _text         = text;
        _seen         = seen;
        _createdAt    = createdAt;
        NSMutableArray *attachmentIds = [[NSMutableArray alloc] init];
        for(KDatabaseObject *attachment in attachments) [attachmentIds addObject:attachment.uniqueId];
        _attachmentIds  = [attachmentIds componentsJoinedByString:@"_"];
    }
    return self;
}

- (NSString *)generateUniqueId {
    NSUInteger uniqueHash = self.authorId.hash ^ (NSUInteger) [self.createdAt timeIntervalSince1970] ^ self.text.hash;
    return [NSString stringWithFormat:@"%@_%lu", [KPost tableName], (unsigned long)uniqueHash];
}

@end
