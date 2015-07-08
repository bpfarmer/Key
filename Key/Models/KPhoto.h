//
//  KPhoto.h
//  Key
//
//  Created by Brendan Farmer on 7/2/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"

@interface KPhoto : KDatabaseObject

@property (nonatomic, readonly) NSString *filename;
@property (nonatomic, readonly) NSData   *media;
@property (nonatomic, readonly) BOOL ephemeral;

- (instancetype)initWithMedia:(NSData *)media ephemeral:(BOOL)ephemeral;

@end