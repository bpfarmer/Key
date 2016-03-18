//
//  NSBundle+Messages.h
//  Key
//
//  Created by Brendan Farmer on 4/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (Messages)

+ (NSBundle *)messagesBundle;
+ (NSBundle *)messagesAssetBundle;
+ (NSString *)localizedStringForKey:(NSString *)key;

@end
