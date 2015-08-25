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
@class KLocation;
@class KPhoto;

@interface KPost : KDatabaseObject <KEncryptable>

@property (nonatomic, readonly) NSString *authorId;
@property (nonatomic, readonly) NSString *text;
@property (nonatomic) NSData *preview;
@property (nonatomic) BOOL ephemeral;
@property (nonatomic) BOOL read;
@property (nonatomic, readonly) NSDate *createdAt;
@property (nonatomic) NSInteger attachmentCount;

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                        authorId:(NSString *)authorId
                            text:(NSString *)text
                       createdAt:(NSDate *)createdAt
                       ephemeral:(BOOL)ephemeral
                 attachmentCount:(NSInteger)attachmentCount;

- (instancetype)initWithAuthorId:(NSString *)authorId;
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
- (void)incrementAttachmentCount;
- (void)decrementAttachmentCount;

@end
