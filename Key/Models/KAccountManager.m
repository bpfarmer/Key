//
//  KAccountManager.m
//  Key
//
//  Created by Brendan Farmer on 2/1/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KAccountManager.h"
#import "KUser.h"
#import "KStorageManager.h"
#import "SendPushTokenRequest.h"
#import "PushManager.h"
#import "CollapsingFutures.h"

@implementation KAccountManager

+ (instancetype)sharedManager {
    static KAccountManager *sharedMyManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}


- (void)setUser:(KUser *)user {
    _user = user;
    [self saveToPlist];
}

- (void)requestPushPermissions {
    if(self.user) {
        TOCFuture *pushNotificationFuture = [[PushManager sharedManager] registerForRemoteNotifications];
        
        [pushNotificationFuture thenDo:^(id value) {
            if(!self.user.uniqueId) {
                KUser *foundUser = [KUser findByDictionary:@{@"username" : self.user.username}];
                if(foundUser) [[PushManager sharedManager] sendPushToken:value user:foundUser];
            }else [[PushManager sharedManager] sendPushToken:value user:self.user];
        }];
    }
}

- (TOCFuture *)asyncGetFeed {
    if(self.user) {
        return self.user.asyncGetFeed;
    }
    return nil;
}

- (NSString *)uniqueId {
    if(self.user) {
        return self.user.uniqueId;
    }
    return nil;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    self.authorizationStatus = status;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    self.currentCoordinate = locations.lastObject;
    NSLog(@"CURRENT COORDINATE: %@", self.currentCoordinate);
    if(!self.streamLocation) {
        [self.locationManager stopUpdatingLocation];
    }
}

- (void)initLocationManager {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    if([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
}

- (void)refreshCurrentCoordinate {
    self.streamLocation = NO;
    [self.locationManager startUpdatingLocation];
}

- (NSDictionary *)plistData {
    NSString *destPath = [self plistPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:destPath]) {
        NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"User" ofType:@"plist"];
        [fileManager copyItemAtPath:sourcePath toPath:destPath error:nil];
    }
    NSLog(@"PLIST DATA: %@", [[NSDictionary alloc] initWithContentsOfFile:destPath]);
    return [[NSDictionary alloc] initWithContentsOfFile:destPath];
}

- (NSString *)plistPath {
    NSString *destPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [destPath stringByAppendingPathComponent:@"User.plist"];
}

- (void)saveToPlist {
    NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithDictionary:self.plistData];
    if(self.user) [plistData setObject:self.user.username forKey:@"username"];
    else [plistData removeObjectForKey:@"username"];
    [plistData writeToFile:self.plistPath atomically:YES];
}

- (BOOL)setUserFromPlist {
    NSString *username = [self.plistData objectForKey:@"username"];
    if(username.length == 0) {
        NSLog(@"FAILING ON USERNAME");
        return NO;
    }
    NSLog(@"USERNAME :%@", username);
    [[KStorageManager sharedManager] setDatabaseWithName:username];
    KUser *user = [KUser findByDictionary:@{@"username" : username}];
    if(!user) {
        NSLog(@"FAILING ON USER QUERY");
        return NO;
    }
    [self setUser:user];
    return YES;
}

@end
