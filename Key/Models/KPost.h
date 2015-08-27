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
#import "KThreadable.h"

@class KAttachment;
@class KUser;
@class KLocation;
@class KPhoto;

@interface KPost : KDatabaseObject <KEncryptable, KThreadable>

@property (nonatomic, readonly) NSString *authorId;
@property (nonatomic, readonly) NSString *text;
@property (nonatomic) NSString *threadId;
@property (nonatomic) NSData *preview;
@property (nonatomic) BOOL ephemeral;
@property (nonatomic) BOOL read;
@property (nonatomic) NSDate *readAt;
@property (nonatomic, readonly) NSDate *createdAt;
@property (nonatomic) NSString *attachmentIds;
@property (nonatomic) NSInteger attachmentCount;

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                        authorId:(NSString *)authorId
                        threadId:(NSString *)threadId
                            text:(NSString *)text
                       createdAt:(NSDate *)createdAt
                       ephemeral:(BOOL)ephemeral
                   attachmentIds:(NSString *)attachmentIds
                 attachmentCount:(NSInteger)attachmentCount;

- (instancetype)initWithAuthorId:(NSString *)authorId;
- (instancetype)initWithAuthorId:(NSString *)authorId threadId:(NSString *)threadId;
- (NSArray *)attachments;
- (KUser *)author;
- (NSData *)previewImage;
- (NSData *)createThumbnailPreview;
+ (NSArray *)unread;
+ (NSArray *)findByAuthorId:(NSString *)authorId;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToFillSize:(CGSize)size;
- (NSString *)displayDate;
- (KLocation *)location;
- (KPhoto *)photo;
- (void)addAttachment:(KDatabaseObject *)attachment;
- (void)decrementAttachmentCount;
- (void)incrementAttachmentCount;


@end
