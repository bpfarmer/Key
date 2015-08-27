//
//  KLocation.h
//  Key
//
//  Created by Brendan Farmer on 7/2/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"
#import <MapKit/MapKit.h>
#import "KAttachable.h"

@interface KLocation : KDatabaseObject <KAttachable>

@property (nonatomic, readonly) NSString *authorId;
@property (nonatomic, readonly) CLLocation *location;
@property (nonatomic, readonly) NSDate *timestamp;
@property (nonatomic) NSString *address;
@property (nonatomic) NSString *parentId;

- (instancetype)initWithAuthorId:(NSString *)authorId location:(CLLocation *)location;
- (instancetype)initWithUniqueId:(NSString *)uniqueId authorId:(NSString *)authorId location:(CLLocation *)location parentId:(NSString *)parentId address:(NSString *)address;

- (NSString *)shortAddress;
- (NSString *)formattedAddress;
@end
