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
#import "KPhoto.h"
#import "KLocation.h"
#import <ImageIO/ImageIO.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "NSData+gzip.h"
#import "NSDate+TimeAgo.h"
#import "KThread.h"
#import "KAccountManager.h"
#import "KObjectRecipient.h"

@implementation KPost

- (instancetype)initWithAuthorId:(NSString *)authorId {
    self = [super initWithUniqueId:[KPost generateUniqueIdWithClass]];
    
    if(self) {
        _authorId        = authorId;
        _createdAt       = [NSDate date];
        _read            = NO;
    }
    
    return self;
}

- (instancetype)initWithUniqueId:(NSString *)uniqueId authorId:(NSString *)authorId threadId:(NSString *)threadId text:(NSString *)text createdAt:(NSDate *)createdAt ephemeral:(BOOL)ephemeral attachmentIds:(NSString *)attachmentIds attachmentCount:(NSInteger)attachmentCount{
    self = [super initWithUniqueId:uniqueId];
    
    if(self) {
        _authorId        = authorId;
        _threadId        = threadId;
        _text            = text;
        _createdAt       = createdAt;
        _ephemeral       = ephemeral;
        _attachmentIds   = attachmentIds;
    }
    return self;
}

- (instancetype)initWithResultSetRow:(NSDictionary *)resultSetRow {
    self = [super initWithResultSetRow:resultSetRow];
    if(self) {
        NSData *zippedMedia = [NSData dataWithContentsOfFile:self.filePath];
        _preview = [zippedMedia gunzippedData];
    }
    return self;
}


- (KUser *)author {
    return [KUser findById:self.authorId];
}

- (void)addRecipientIds:(NSArray *)recipientIds {
    for(NSString *recipientId in recipientIds)
        if(![recipientId isEqualToString:self.authorId])
            [[[KObjectRecipient alloc] initWithObjectId:self.uniqueId recipientId:recipientId] save];
}

- (NSArray *)threadIds {
    NSMutableArray *threadIds = [NSMutableArray new];
    if(self.threadId) {
        [threadIds addObject:self.threadId];
    }else {
        NSMutableArray *userIds = [NSMutableArray new];
        if([self.authorId isEqualToString:[KAccountManager sharedManager].user.uniqueId]) {
            NSArray *objectRecipients = [KObjectRecipient findAllByDictionary:@{@"objectId" : self.uniqueId}];
            for(KObjectRecipient *or in objectRecipients) {
                userIds = [NSMutableArray arrayWithObjects:or.recipientId, self.authorId, nil];
                [userIds sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
                    return [obj1 compare:obj2];
                }];
                [threadIds addObject:[KThread uniqueIdFromUserIds:userIds]];
            }
        }else {
            userIds = [NSMutableArray arrayWithObjects:self.authorId, [KAccountManager sharedManager].user.uniqueId, nil];
            [userIds sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
                return [obj1 compare:obj2];
            }];
            if(!self.threadId) {
                self.threadId = [KThread uniqueIdFromUserIds:userIds];
                [super save];
            }
            [threadIds addObject:self.threadId];
        }
    }
    return [threadIds copy];
}

- (NSArray *)threads {
    NSMutableArray *threads = [NSMutableArray new];
    for(NSString *threadId in self.threadIds) {
        [threads addObject:[KThread findById:threadId]];
    }
    return [threads copy];
}

- (void)setupThreads {
    for(NSString *threadId in self.threadIds) if(![KThread findById:threadId]) [[[KThread alloc] initWithUniqueId:threadId] save];
}

- (void)save {
    [super save];
    [self processForThread];
}

- (void)processForThread {
    [self setupThreads];
    for(KThread *thread in self.threads) [thread processLatestMessage:self];
}

+ (NSArray *)unread {
    return [[KStorageManager sharedManager] querySelectObjects:^NSArray *(FMDatabase *database) {
        FMResultSet *result = [database executeQuery:[NSString stringWithFormat:@"select * from %@ where read = 0 AND author_id <> :user_id order by created_at desc", [self tableName]] withParameterDictionary:@{@"user_id" : [KAccountManager sharedManager].user.uniqueId}];
        NSMutableArray *posts = [[NSMutableArray alloc] init];
        while(result.next) {
            KPost *post = [[KPost alloc] initWithResultSetRow:result.resultDictionary];
            [posts addObject:post];
        }
        [result close];
        return [posts copy];
    }];
}

+ (NSArray *)findByAuthorId:(NSString *)authorId {
    return [[KStorageManager sharedManager] querySelectObjects:^NSArray *(FMDatabase *database) {
        FMResultSet *result = [database executeQuery:[NSString stringWithFormat:@"select * from %@ where author_id = :unique_id and ephemeral = 0 order by created_at desc", [self tableName]] withParameterDictionary:@{@"unique_id" : authorId}];
        NSMutableArray *posts = [[NSMutableArray alloc] init];
        while(result.next) {
            KPost *post = [[KPost alloc] initWithResultSetRow:result.resultDictionary];
            [posts addObject:post];
        }
        [result close];
        return [posts copy];
    }];
}

+ (NSArray *)unsavedPropertyList {
    NSMutableArray *unsavedProperties = [[NSMutableArray alloc] initWithArray:[super unsavedPropertyList]];
    [unsavedProperties addObjectsFromArray:@[@"preview"]];
    return unsavedProperties;
}

- (NSString *)filePath {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    return [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:self.uniqueId]];
}

- (NSData *)previewImage {
    if(!self.preview) return [self createThumbnailPreviewWithData:nil];
    return self.preview;
}

- (NSData *)createThumbnailPreviewWithData:(NSData *)imageData {
    if(!imageData) {
        KPhoto *photo = (KPhoto *)[self attachmentsOfType:NSStringFromClass([KPhoto class])].firstObject;
        if(!photo || !photo.media) return nil;
        imageData = photo.media;
    }
    
    NSData *zippedMedia = [NSData dataWithContentsOfFile:self.filePath];
    self.preview = [zippedMedia gunzippedData];
    if(self.preview) return self.preview;
    
    CGImageRef        previewImage = NULL;
    CFDictionaryRef   options = NULL;
    CFStringRef       keys[3];
    CFTypeRef         values[3];
    CFNumberRef       thumbnailSize;
    
    int imageSize = 40;
    
    CGImageSourceRef fullsizeImageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    if(fullsizeImageSource == NULL) {
        fprintf(stderr, "Image source is NULL.");
    }
    
    thumbnailSize = CFNumberCreate(NULL, kCFNumberIntType, &imageSize);
    
    // Set up the thumbnail options.
    keys[0] = kCGImageSourceCreateThumbnailWithTransform;
    values[0] = (CFTypeRef)kCFBooleanTrue;
    keys[1] = kCGImageSourceCreateThumbnailFromImageIfAbsent;
    values[1] = (CFTypeRef)kCFBooleanTrue;
    keys[2] = kCGImageSourceThumbnailMaxPixelSize;
    values[2] = (CFTypeRef)thumbnailSize;
    
    options = CFDictionaryCreate(NULL, (const void **) keys, (const void **) values, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    previewImage = CGImageSourceCreateThumbnailAtIndex(fullsizeImageSource, 0, options);
    
    CFRelease(thumbnailSize);
    CFRelease(options);
    CFRelease(fullsizeImageSource);
    
    // Make sure the thumbnail image exists before continuing.
    if(previewImage == NULL) {
        fprintf(stderr, "Thumbnail image not created from image source.");
    }
    
    self.preview = UIImagePNGRepresentation([UIImage imageWithCGImage:previewImage]);
    [self.preview.gzippedData writeToFile:self.filePath atomically:YES];
    CFRelease(previewImage);
    return self.preview;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToFillSize:(CGSize)size {
    CGFloat scale = MAX(size.width/image.size.width, size.height/image.size.height);
    CGFloat width = image.size.width * scale;
    CGFloat height = image.size.height * scale;
    CGRect imageRect = CGRectMake((size.width - width)/2.0f,
                                  (size.height - height)/2.0f,
                                  width,
                                  height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [image drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (NSString *)displayDate {
    return self.createdAt.formattedAsTimeAgo;
}

- (void)addAttachment:(KDatabaseObject <KAttachable> *)attachment {
    NSMutableArray *attachments = [NSMutableArray arrayWithArray:[self.attachmentIds componentsSeparatedByString:@"__"]];
    [attachments addObject:attachment.uniqueId];
    self.attachmentIds = [attachments componentsJoinedByString:@"__"];
    attachment.parentId = self.uniqueId;
    [attachment save];
    [self processSavedAttachment:attachment];
}

- (void)processSavedAttachment:(KDatabaseObject<KAttachable> *)attachment {
    if([attachment isKindOfClass:[KPhoto class]]) {
        [self createThumbnailPreviewWithData:((KPhoto *)attachment).media];
        [self save];
    }
}

+ (NSString *)generateUniqueId {
    return [self generateUniqueIdWithClass];
}

- (NSArray *)attachments {
    NSMutableArray *attachments = [NSMutableArray new];
    for(NSString *attachmentId in [self.attachmentIds componentsSeparatedByString:@"__"]) {
        NSString *className = [attachmentId componentsSeparatedByString:@"_"].firstObject;
        NSString *uniqueId  = attachmentId;
        KDatabaseObject *object = [NSClassFromString(className) findById:uniqueId];
        if(object) [attachments addObject:object];
    }
    return [attachments copy];
}

- (NSArray *)attachmentsOfType:(NSString *)type {
    NSMutableArray *ids = [NSMutableArray new];
    for(NSString *attachmentId in [self.attachmentIds componentsSeparatedByString:@"__"]) {
        if([[attachmentId componentsSeparatedByString:@"_"].firstObject isEqualToString:type])
            [ids addObject:attachmentId];
    }
    return [NSClassFromString(type) findAllByIds:ids];
}

- (void)remove {
    [super remove];
    for(KDatabaseObject *attachment in self.attachments) [attachment remove];
}


@end
