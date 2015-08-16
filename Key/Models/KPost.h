//
//  KPost.h
//  Key
//
//  Created by Brendan Farmer on 4/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"
#import "KEncryptable.h"
#import <UIKit/UIKit.h>

@class KAttachment;
@class KUser;

@interface KPost : KDatabaseObject <KEncryptable>

@property (nonatomic, readonly) NSString *authorId;
@property (nonatomic, readonly) NSString *text;
@property (nonatomic) NSData *preview;
@property (nonatomic) BOOL ephemeral;
@property (nonatomic) BOOL read;
@property (nonatomic, readonly) NSDate *createdAt;
@property (nonatomic) NSString *attachmentIds;

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                        authorId:(NSString *)authorId
                            text:(NSString *)text
                       createdAt:(NSDate *)createdAt
                       ephemeral:(BOOL)ephemeral;

- (instancetype)initWithAuthorId:(NSString *)authorId text:(NSString *)text;
- (NSArray *)attachments;
- (KUser *)author;
- (NSData *)previewImage;
+ (NSArray *)unread;
+ (NSArray *)findByAuthorId:(NSString *)authorId;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToFillSize:(CGSize)size;
- (NSString *)displayDate;

@end
