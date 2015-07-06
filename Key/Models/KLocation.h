//
//  KLocation.h
//  Key
//
//  Created by Brendan Farmer on 7/2/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDatabaseObject.h"
#import <MapKit/MapKit.h>

@interface KLocation : KDatabaseObject

@property (nonatomic, readonly) NSString *userUniqueId;
@property (nonatomic, readonly) CLLocation *location;
@property (nonatomic, readonly) NSDate *timestamp;

- (instancetype)initWithUserUniqueId:(NSString *)userUniqueId location:(CLLocation *)location;

@end
