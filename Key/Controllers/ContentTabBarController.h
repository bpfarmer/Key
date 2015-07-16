//
//  ContentTabBarController.h
//  Key
//
//  Created by Brendan Farmer on 7/16/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContentTabBar.h"

@class InboxViewController;
@class SocialViewController;

@interface ContentTabBarController : UITabBarController

@property (nonatomic, strong) InboxViewController *inboxVC;
@property (nonatomic, strong) SocialViewController *socialVC;

@end
