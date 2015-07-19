//
//  KDevice.m
//  Key
//
//  Created by Brendan Farmer on 7/19/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KDevice.h"

@implementation KDevice

- (instancetype)initWithUserId:(NSString *)userId deviceId:(NSString *)deviceId isCurrentDevice:(BOOL)isCurrentDevice {
    self = [super init];
    if(self) {
        _userId = userId;
        _deviceId = deviceId;
        _isCurrentDevice = isCurrentDevice;
    }
    
    return self;
}

@end
