//
//  UIAlertController+Orientation.m
//  Key
//
//  Created by Brendan Farmer on 9/25/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "UIAlertController+Orientation.h"

@implementation UIAlertController(Orientation)

#pragma mark self rotate
- (BOOL)shouldAutorotate {
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    if ( orientation == UIDeviceOrientationPortrait
        | orientation == UIDeviceOrientationPortraitUpsideDown) {
        
        return YES;
    }
    
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    
    return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    UIDevice* device = [UIDevice currentDevice];
    if (device.orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return UIInterfaceOrientationPortraitUpsideDown;
    }
    return UIInterfaceOrientationPortrait;
}

@end
