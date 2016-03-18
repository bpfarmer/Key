//
//  UIDevice+Messages.h
//  Key
//
//  Created by Brendan Farmer on 4/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (Messages)

/**
 *  @return Whether or not the current device is running a version of iOS before 8.0.
 */
+ (BOOL)isCurrentDeviceBeforeiOS8;

@end

