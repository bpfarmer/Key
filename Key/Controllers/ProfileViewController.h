//
//  ProfileViewController.h
//  Key
//
//  Created by Brendan Farmer on 8/13/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KTableViewController.h"

@class KUser;

@interface ProfileViewController : KTableViewController

@property (nonatomic) KUser *user;

@end
