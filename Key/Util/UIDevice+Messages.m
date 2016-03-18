//
//  UIDevice+Messages.m
//  Key
//
//  Created by Brendan Farmer on 4/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "UIDevice+Messages.h"

@implementation UIDevice (Messages)

+ (BOOL)isCurrentDeviceBeforeiOS8
{
    // iOS < 8.0
    return [[UIDevice currentDevice].systemVersion compare:@"8.0.0" options:NSNumericSearch] == NSOrderedAscending;
}

@end

