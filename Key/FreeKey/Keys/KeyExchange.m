//
//  KeyExchange.m
//  Key
//
//  Created by Brendan Farmer on 7/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KeyExchange.h"
#import "KDevice.h"

@implementation KeyExchange

+ (NSArray *)remoteKeys {
    return nil;
}

- (NSString *)remoteDeviceId {
    return nil;
}

- (NSString *)remoteUserId {
    return nil;
}

- (void)saveAndAddDevice {
    [self save];
    [KDevice addDeviceForUserId:self.remoteUserId deviceId:self.remoteDeviceId];
}

@end
