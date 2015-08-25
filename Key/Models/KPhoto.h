//
//  KPhoto.h
//  Key
//
//  Created by Brendan Farmer on 7/2/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"
#import "KAttachable.h"

@interface KPhoto : KDatabaseObject <KAttachable>

@property (nonatomic, readonly) BOOL ephemeral;
@property (nonatomic) NSData *media;
@property (nonatomic) NSString *parentId;

- (instancetype)initWithMedia:(NSData *)media;
- (instancetype)initWithMedia:(NSData *)media ephemeral:(BOOL)ephemeral parentId:(NSString *)parentId;

@end
