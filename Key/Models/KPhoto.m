//
//  KPhoto.m
//  Key
//
//  Created by Brendan Farmer on 7/2/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KPhoto.h"
#import "NSData+gzip.h"
#import "KPost.h"

@implementation KPhoto

- (instancetype)initWithMedia:(NSData *)media ephemeral:(BOOL)ephemeral {
    self = [super initWithUniqueId:[self.class generateUniqueId]];
    
    if(self) {
        _media = media;
        _ephemeral = ephemeral;
    }
    
    return self;
}

- (instancetype)initWithResultSetRow:(NSDictionary *)resultSetRow {
    self = [super initWithResultSetRow:resultSetRow];
    if(self) {
        NSData *zippedMedia = [NSData dataWithContentsOfFile:self.filePath];
        _media = [zippedMedia gunzippedData];
    }
    return self;
}

- (instancetype)initWithMedia:(NSData *)media ephemeral:(BOOL)ephemeral parentId:(NSString *)parentId {
    self = [super initWithUniqueId:[self.class generateUniqueId]];
    
    if(self) {
        _media = media;
        _ephemeral = ephemeral;
        _parentId  = parentId;
        [[KPost findById:parentId] createThumbnailPreview];
    }
    
    return self;
}

- (void)save {
    if([self.uniqueId isEqualToString:@""]) {
        [[KPost findById:self.parentId] createThumbnailPreview];
        NSLog(@"SHOULD BE CREATING THUMBNAIL PREVIEW");
    }
    [super save];
    NSData *zippedMedia = self.media.gzippedData;
    [zippedMedia writeToFile:self.filePath atomically:YES];
}

+ (NSArray *)unsavedPropertyList {
    NSMutableArray *unsavedProperties = [[NSMutableArray alloc] initWithArray:[super unsavedPropertyList]];
    [unsavedProperties addObject:@"media"];
    return unsavedProperties;
}

- (NSString *)filePath {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    return [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:self.uniqueId]];
}

@end
