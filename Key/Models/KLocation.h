//
//  KLocation.h
//  Key
//
//  Created by Brendan Farmer on 7/2/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KYapDatabaseObject.h"
#import <MapKit/MapKit.h>

@interface KLocation : KYapDatabaseObject

@property (nonatomic, readonly) NSString *userUniqueId;
@property (nonatomic, readonly) CLLocation *location;

- (instancetype)initWithUserUniqueId:(NSString *)userUniqueId location:(CLLocation *)location;

@end
