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

- (instancetype)initWithMedia:(NSData *)media {
    self = [super initWithUniqueId:[self.class generateUniqueIdWithClass]];
    
    if(self) {
        _media = media;
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

- (instancetype)initWithUniqueId:(NSString *)uniqueId media:(NSData *)media ephemeral:(BOOL)ephemeral parentId:(NSString *)parentId {
    self = [super initWithUniqueId:uniqueId];
    
    if(self) {
        _media = media;
        _ephemeral = ephemeral;
        _parentId  = parentId;
        KPost *parentPost = [KPost findById:parentId];
        if(parentPost) [parentPost processSavedAttachment:self];
    }
    
    return self;
}

- (void)save {
    NSData *zippedMedia = self.media.gzippedData;
    [zippedMedia writeToFile:self.filePath atomically:YES];
    [super save];
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
