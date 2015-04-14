//
//  UIImage+Messages.h
//  Key
//
//  Created by Brendan Farmer on 4/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Messages)

- (UIImage *)imageMaskedWithColor:(UIColor *)maskColor;
+ (UIImage *)bubbleRegularImage;
+ (UIImage *)bubbleRegularTaillessImage;
+ (UIImage *)bubbleRegularStrokedImage;
+ (UIImage *)bubbleRegularStrokedTaillessImage;
+ (UIImage *)bubbleCompactImage;
+ (UIImage *)bubbleCompactTaillessImage;
+ (UIImage *)defaultAccessoryImage;
+ (UIImage *)defaultTypingIndicatorImage;
+ (UIImage *)defaultPlayImage;

@end