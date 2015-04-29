//
//  SelectRecipientViewController.h
//  Key
//
//  Created by Brendan Farmer on 4/29/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KPost;
@class KUser;

@interface SelectRecipientViewController : UIViewController

@property (nonatomic) KPost *post;
@property (nonatomic) KUser *currentUser;

@end
