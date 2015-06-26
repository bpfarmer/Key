//
//  HomeViewController.h
//  Key
//
//  Created by Brendan Farmer on 3/18/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KUser;

static NSString *kSelectRecipientSegueIdentifier = @"selectRecipientsPushSegue";
static NSString *kThreadSeguePush        = @"threadSeguePush";
static NSString *kContactsSeguePush      = @"contactsSeguePush";
static NSString *kShareViewSegue         = @"shareViewSegue";

@interface HomeViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;

@property (nonatomic) KUser *currentUser;

@end
