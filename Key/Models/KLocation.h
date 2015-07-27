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

@property (nonatomic, readonly) NSString *userUniqueId;
@property (nonatomic, readonly) CLLocation *location;
@property (nonatomic, readonly) NSDate *timestamp;
@property (nonatomic) NSString *parentId;

- (instancetype)initWithUserUniqueId:(NSString *)userUniqueId location:(CLLocation *)location;

@end
