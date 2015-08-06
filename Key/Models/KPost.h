//
//  KPost.h
//  Key
//
//  Created by Brendan Farmer on 4/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"
#import "KEncryptable.h"

@class KAttachment;
@class KUser;

@interface KPost : KDatabaseObject <KEncryptable>

@property (nonatomic, readonly) NSString *authorId;
@property (nonatomic, readonly) NSString *text;
@property (nonatomic) NSString *attachmentIds;
@property (nonatomic) BOOL seen;
@property (nonatomic, readonly) NSDate *createdAt;

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                        authorId:(NSString *)authorId
                            text:(NSString *)text
                      attachments:(NSArray *)attachments
                            seen:(BOOL)seen
                       createdAt:(NSDate *)createdAt;

- (instancetype)initWithAuthorId:(NSString *)authorId text:(NSString *)text;
- (NSArray *)attachments;
- (KUser *)author;

@end
