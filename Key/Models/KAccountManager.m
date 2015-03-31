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
        if([PushManager sharedManager].pushToken)
            [SendPushTokenRequest makeRequestWithDeviceToken:[PushManager sharedManager].pushToken uniqueId:user.uniqueId];
    }
}

@end
