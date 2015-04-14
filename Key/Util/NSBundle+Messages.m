//
//  NSBundle+Messages.m
//  Key
//
//  Created by Brendan Farmer on 4/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "NSBundle+Messages.h"
#import "ThreadViewController.h"

@implementation NSBundle (Messages)

+ (NSBundle *)messagesBundle
{
    return [NSBundle bundleForClass:[ThreadViewController class]];
}

+ (NSBundle *)messagesAssetBundle
{
    NSString *bundleResourcePath = [NSBundle messagesBundle].resourcePath;
    NSString *assetPath = [bundleResourcePath stringByAppendingPathComponent:@"MessagesAssets.bundle"];
    return [NSBundle bundleWithPath:assetPath];
}

+ (NSString *)localizedStringForKey:(NSString *)key
{
    return NSLocalizedStringFromTableInBundle(key, @"Messages", [NSBundle messagesAssetBundle], nil);
}

@end
