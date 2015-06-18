//
//  SocialViewController.h
//  Key
//
//  Created by Brendan Farmer on 4/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KUser;
@class KPost;

@interface SocialViewController : UIViewController

@property (nonatomic) KUser *currentUser;
@property (nonatomic) KPost *currentPost;

@end
