//
//  HomeViewController.h
//  Key
//
//  Created by Brendan Farmer on 3/18/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DismissAndPresentProtocol.h"

@class KUser;
@class KThread;

static NSString *kSelectRecipientSegueIdentifier = @"selectRecipientsPushSegue";
static NSString *kThreadSeguePush        = @"threadSeguePush";
static NSString *kContactsSeguePush      = @"contactsSeguePush";
static NSString *kShareViewSegue         = @"shareViewSegue";

@interface HomeViewController : UIViewController <DismissAndPresentProtocol>

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic) KThread *selectedThread;

@property (nonatomic) KUser *currentUser;

@end
