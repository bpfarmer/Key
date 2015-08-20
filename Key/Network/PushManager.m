//
//  PushManager.m
//  Key
//
//  Created by Brendan Farmer on 3/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "PushManager.h"
#import "FreeKey.h"
#import "KAccountManager.h"
#import "KUser.h"
#import <UIKit/UIKit.h>
#import "SendPushTokenRequest.h"
#import "CollapsingFutures.h"

@class TOCFuture;

@implementation PushManager

+ (instancetype)sharedManager {
    static PushManager *sharedMyManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)respondToRemoteNotification {
    KUser *currentUser = [KAccountManager sharedManager].user;
    if(currentUser) {
        [currentUser asyncGetFeed];
    }
}

- (TOCFuture *)registerForRemoteNotifications {
    self.userNotificationFutureSource = [TOCFutureSource new];
    
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    }
    
    return self.userNotificationFutureSource.future;
}

- (void)sendPushToken:(NSData *)pushToken userId:(NSString *)userId {
    [SendPushTokenRequest makeRequestWithDeviceToken:pushToken uniqueId:userId];
}

@end
