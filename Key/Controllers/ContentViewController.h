//
//  ContentViewController.h
//  Key
//
//  Created by Brendan Farmer on 7/16/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ContentTabBarController;
@class HomeViewController;

@interface ContentViewController : UIViewController

@property (nonatomic, strong) IBOutlet ContentTabBarController *contentTC;
@property (nonatomic) HomeViewController *homeViewController;

@end
