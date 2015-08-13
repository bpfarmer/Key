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
        _read     = NO;
        [self setUniqueId:[self generateUniqueId]];
    }
    
    return self;
}

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                        authorId:(NSString *)authorId
                            text:(NSString *)text
                     attachments:(NSArray *)attachments
                       createdAt:(NSDate *)createdAt{
    self = [super initWithUniqueId:uniqueId];
    
    if(self) {
        _authorId     = authorId;
        _text         = text;
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

- (NSArray *)attachments {
    NSMutableArray *attachments = [NSMutableArray new];
    KPhoto *photo = [KPhoto findByDictionary:@{@"parentId" : self.uniqueId}];
    if(photo) [attachments addObject:photo];
    KLocation *location = [KLocation findByDictionary:@{@"parentId" : self.uniqueId}];
    if(location) [attachments addObject:location];
    return [attachments copy];
}

+ (NSArray *)unread {
    return [[KStorageManager sharedManager] querySelectObjects:^NSArray *(FMDatabase *database) {
        FMResultSet *result = [database executeQuery:[NSString stringWithFormat:@"select * from %@ where read = 0", [self tableName]]];
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

- (void)save {
    [super save];
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
    KPhoto *photo = [KPhoto findByDictionary:@{@"parentId" : self.uniqueId}];
    NSLog(@"RETRIEVED PHOTO: %@", photo);
    if(!photo || !photo.media) return nil;
    
    NSData *media = photo.media;
    
    CGImageRef        previewImage = NULL;
    CFDictionaryRef   options = NULL;
    CFStringRef       keys[3];
    CFTypeRef         values[3];
    CFNumberRef       thumbnailSize;
    
    int imageSize = 40;
    
    CGImageSourceRef fullsizeImageSource = CGImageSourceCreateWithData((CFDataRef)media, NULL);
    if (fullsizeImageSource == NULL){
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
    //CFRelease(keys);
    //CFRelease(values);
    
    // Make sure the thumbnail image exists before continuing.
    if (previewImage == NULL){
        fprintf(stderr, "Thumbnail image not created from image source.");
    }
    
    self.preview = UIImagePNGRepresentation([UIImage imageWithCGImage:previewImage]);
    [self.preview.gzippedData writeToFile:self.filePath atomically:YES];
    CFRelease(previewImage);
    return self.preview;
}

@end
