//
//  PushManager.h
//  Key
//
//  Created by Brendan Farmer on 3/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TOCFutureSource;
@class TOCFuture;
@class KUser;

@interface PushManager : NSObject

@property (nonatomic, weak) NSData *pushToken;
@property TOCFutureSource *userNotificationFutureSource;

+ (instancetype)sharedManager;
- (void)respondToRemoteNotification;
- (TOCFuture *)registerForRemoteNotifications;
- (void)sendPushToken:(NSData *)pushToken user:(KUser *)user;
- (void)requestPermissionsForUser:(KUser *)user;

@end
