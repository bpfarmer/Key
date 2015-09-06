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
#import "KAttachable.h"

@class KAttachment;
@class KUser;
@class KLocation;
@class KPhoto;
@class KThread;

@interface KPost : KDatabaseObject <KEncryptable, KThreadable>

@property (nonatomic) NSString *authorId;
@property (nonatomic, readonly) NSString *text;
@property (nonatomic) NSString *threadId;
@property (nonatomic) NSData *preview;
@property (nonatomic) BOOL ephemeral;
@property (nonatomic) BOOL read;
@property (nonatomic) NSDate *readAt;
@property (nonatomic) NSDate *createdAt;
@property (nonatomic) NSString *attachmentIds;

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                        authorId:(NSString *)authorId
                        threadId:(NSString *)threadId
                            text:(NSString *)text
                       createdAt:(NSDate *)createdAt
                       ephemeral:(BOOL)ephemeral
                   attachmentIds:(NSString *)attachmentIds
                 attachmentCount:(NSInteger)attachmentCount;

- (instancetype)initWithAuthorId:(NSString *)authorId;
- (KUser *)author;
- (NSData *)previewImage;
+ (NSArray *)unread;
+ (NSArray *)findByAuthorId:(NSString *)authorId;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToFillSize:(CGSize)size;
- (NSString *)displayDate;
- (NSArray *)threads;
- (NSArray *)attachments;
- (NSArray *)attachmentsOfType:(NSString *)type;
- (void)addAttachment:(KDatabaseObject *)attachment;
- (void)processSavedAttachment:(KDatabaseObject <KAttachable> *)attachment;


@end
