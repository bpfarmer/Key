//
//  PushManager.m
//  Key
//
//  Created by Brendan Farmer on 3/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "PushManager.h"
#import "FreeKey.h"

@implementation PushManager

+ (instancetype)sharedManager {
    static PushManager *sharedMyManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}


@end
