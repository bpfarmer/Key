//
//  KAccountManager.h
//  Key
//
//  Created by Brendan Farmer on 2/1/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class KUser;
@class TOCFuture;

@interface KAccountManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic) KUser *user;
@property (nonatomic) CLAuthorizationStatus authorizationStatus;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) CLLocation *currentCoordinate;
@property (nonatomic) BOOL streamLocation;

+ (instancetype)sharedManager;

- (TOCFuture *)asyncGetFeed;
- (NSString *)uniqueId;
- (void)initLocationManager;
- (void)refreshCurrentCoordinate;

@end
