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
    if(self) {
        _user = user;
        
        if(user.uniqueId) {
            TOCFuture *pushNotificationFuture = [[PushManager sharedManager] registerForRemoteNotifications];
        
            [pushNotificationFuture thenDo:^(id value) {
                [[PushManager sharedManager] sendPushToken:value userId:self.user.uniqueId];
            }];
        }
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

@end
