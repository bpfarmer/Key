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

@implementation KPost

- (KUser *)author {
    return [KUser findById:self.authorId];
}

- (instancetype)initWithAuthorId:(NSString *)authorId {
    self = [super init];
    
    if(self) {
        _authorId        = authorId;
        _createdAt       = [NSDate date];
        _read            = NO;
    }
    
    return self;
}

- (instancetype)initWithAuthorId:(NSString *)authorId threadId:(NSString *)threadId {
    self = [super init];
    
    if(self) {
        _authorId        = authorId;
        _threadId        = threadId;
        _createdAt       = [NSDate date];
        _read            = NO;
    }
    
    return self;
}

- (instancetype)initWithUniqueId:(NSString *)uniqueId authorId:(NSString *)authorId threadId:(NSString *)threadId text:(NSString *)text createdAt:(NSDate *)createdAt ephemeral:(BOOL)ephemeral attachmentIds:(NSString *)attachmentIds attachmentCount:(NSInteger)attachmentCount{
    self = [super initWithUniqueId:uniqueId];
    
    if(self) {
        _authorId        = authorId;
        if(threadId) {
            _threadId = threadId;
        }else {
            NSArray *userIds = @[authorId, [KAccountManager sharedManager].user.uniqueId];
            KThread *thread = [KThread findWithUserIds:userIds];
            if(!thread) {
                thread = [[KThread alloc] initWithUsers:userIds];
                [thread save];
            }
            _threadId = thread.uniqueId;
        }
        _text            = text;
        _createdAt       = createdAt;
        _ephemeral       = ephemeral;
        _attachmentIds   = attachmentIds;
        _attachmentCount = attachmentCount;
    }
    
    return self;
}

- (void)save {
    [super save];
    [self.thread processLatestMessage:self];
}

- (NSString *)generateUniqueId {
    NSUInteger uniqueHash = self.authorId.hash ^ (NSUInteger) [self.createdAt timeIntervalSince1970] ^ self.text.hash;
    return [NSString stringWithFormat:@"%@_%lu", [KPost tableName], (unsigned long)uniqueHash];
}

- (NSArray *)attachments {
    NSMutableArray *attachments = [NSMutableArray new];
    for(NSString *attachmentId in [self.attachmentIds componentsSeparatedByString:@"__"]) {
        NSString *className = [attachmentId componentsSeparatedByString:@"_"].firstObject;
        NSString *uniqueId  = [attachmentId componentsSeparatedByString:@"_"].lastObject;
        [attachments addObject:[NSClassFromString(className) findById:uniqueId]];
    }
    return [attachments copy];
}

- (KLocation *)location {
    for(KDatabaseObject *attachment in self.attachments) if([attachment isKindOfClass:[KLocation class]]) return (KLocation *) attachment;
    return nil;
}

- (KPhoto *)photo {
    for(KDatabaseObject *attachment in self.attachments) if([attachment isKindOfClass:[KPhoto class]]) return (KPhoto *) attachment;
    return nil;
}

+ (NSArray *)unread {
    return [[KStorageManager sharedManager] querySelectObjects:^NSArray *(FMDatabase *database) {
        FMResultSet *result = [database executeQuery:[NSString stringWithFormat:@"select * from %@ where read = 0 order by created_at desc", [self tableName]]];
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
    if(!self.preview) {
        NSData *zippedMedia = [NSData dataWithContentsOfFile:self.filePath];
        self.preview = [zippedMedia gunzippedData];
        if(!self.preview) return [self createThumbnailPreview];
    }
    return self.preview;
}

- (NSData *)createThumbnailPreview {
    KPhoto *photo = self.photo;
    if(!photo || !photo.media) return nil;
    
    NSData *zippedMedia = [NSData dataWithContentsOfFile:self.filePath];
    self.preview = [zippedMedia gunzippedData];
    if(self.preview) return self.preview;
    
    NSData *media = photo.media;
    
    CGImageRef        previewImage = NULL;
    CFDictionaryRef   options = NULL;
    CFStringRef       keys[3];
    CFTypeRef         values[3];
    CFNumberRef       thumbnailSize;
    
    int imageSize = 40;
    
    CGImageSourceRef fullsizeImageSource = CGImageSourceCreateWithData((CFDataRef)media, NULL);
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
    [self decrementAttachmentCount];
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

- (void)addAttachment:(KDatabaseObject *)attachment {
    NSMutableArray *attachments = [NSMutableArray arrayWithArray:[self.attachmentIds componentsSeparatedByString:@"__"]];
    [attachments addObject:[NSString stringWithFormat:@"%@_%@", NSStringFromClass(attachment.class), attachment.uniqueId]];
    self.attachmentIds = [attachments componentsJoinedByString:@"__"];
}

- (void)incrementAttachmentCount {
    self.attachmentCount = self.attachmentCount + 1;
    [self save];
}

- (void)decrementAttachmentCount {
    if(self.attachmentCount > 0) self.attachmentCount = self.attachmentCount - 1;
    [self save];
}

- (KThread *)thread {
    return [KThread findById:self.threadId];
}

@end
