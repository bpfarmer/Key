//
//  UIImage+Messages.m
//  Key
//
//  Created by Brendan Farmer on 4/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "UIImage+Messages.h"
#import "NSBundle+Messages.h"


@implementation UIImage (Messages)

- (UIImage *)imageMaskedWithColor:(UIColor *)maskColor
{
    NSParameterAssert(maskColor != nil);
    
    CGRect imageRect = CGRectMake(0.0f, 0.0f, self.size.width, self.size.height);
    UIImage *newImage = nil;
    
    UIGraphicsBeginImageContextWithOptions(imageRect.size, NO, self.scale);
    {
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextScaleCTM(context, 1.0f, -1.0f);
        CGContextTranslateCTM(context, 0.0f, -(imageRect.size.height));
        
        CGContextClipToMask(context, imageRect, self.CGImage);
        CGContextSetFillColorWithColor(context, maskColor.CGColor);
        CGContextFillRect(context, imageRect);
        
        newImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage *)bubbleImageFromBundleWithName:(NSString *)name
{
    NSBundle *bundle = [NSBundle messagesAssetBundle];
    NSString *path = [bundle pathForResource:name ofType:@"png" inDirectory:@"Images"];
    return [UIImage imageWithContentsOfFile:path];
}

+ (UIImage *)bubbleRegularImage
{
    return [UIImage bubbleImageFromBundleWithName:@"bubble_regular"];
}

+ (UIImage *)bubbleRegularTaillessImage
{
    return [UIImage bubbleImageFromBundleWithName:@"bubble_tailless"];
}

+ (UIImage *)bubbleRegularStrokedImage
{
    return [UIImage bubbleImageFromBundleWithName:@"bubble_stroked"];
}

+ (UIImage *)bubbleRegularStrokedTaillessImage
{
    return [UIImage bubbleImageFromBundleWithName:@"bubble_stroked_tailless"];
}

+ (UIImage *)bubbleCompactImage
{
    return [UIImage bubbleImageFromBundleWithName:@"bubble_min"];
}

+ (UIImage *)bubbleCompactTaillessImage
{
    return [UIImage bubbleImageFromBundleWithName:@"bubble_min_tailless"];
}

+ (UIImage *)defaultAccessoryImage
{
    return [UIImage bubbleImageFromBundleWithName:@"clip"];
}

+ (UIImage *)defaultTypingIndicatorImage
{
    return [UIImage bubbleImageFromBundleWithName:@"typing"];
}

+ (UIImage *)defaultPlayImage
{
    return [UIImage bubbleImageFromBundleWithName:@"play"];
}


@end
