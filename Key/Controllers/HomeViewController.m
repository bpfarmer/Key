//
//  HomeViewController.m
//  Key
//
//  Created by Brendan Farmer on 3/18/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HomeViewController.h"
#import "KUser.h"
#import "KAccountManager.h"
#import "KThread.h"
#import "KStorageManager.h"
#import "KMessage.h"
#import "KPost.h"
#import "ThreadViewController.h"
#import "LoginViewController.h"
#import "PushManager.h"
#import "InboxViewController.h"
#import "SocialViewController.h"
#import "ShareViewController.h"
#import "SelectRecipientViewController.h"
#import "ContentViewController.h"
#import "ContentTabBarController.h"

static NSString *TableViewCellIdentifier = @"Threads";

@interface HomeViewController () <CLLocationManagerDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

@end


@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    ContentViewController *contentVC = [ContentViewController new];
    [[NSBundle mainBundle] loadNibNamed:@"ContentView" owner:contentVC options:nil];
    
    self.scrollView.delegate = self;
    
    [self addChildViewController:contentVC];
    [self.scrollView addSubview:contentVC.contentTC.view];
    [contentVC didMoveToParentViewController:self];
    [self addChildViewController:contentVC.contentTC];
    
    CGRect adminFrame = contentVC.view.frame;
    adminFrame.origin.x = adminFrame.size.width;
    
    
    ShareViewController *shareViewController = [[ShareViewController alloc] initWithNibName:@"ShareView" bundle:nil];
    [self addChildViewController:shareViewController];
    [self.scrollView addSubview:shareViewController.view];
    
    shareViewController.view.frame = adminFrame;
    
    CGRect shareFrame = shareViewController.view.frame;
    shareFrame.origin.x = shareFrame.size.width;
    
    // 4) Finally set the size of the scroll view that contains the frames
    CGFloat scrollWidth  = 2 * self.view.frame.size.width;
    CGFloat scrollHeight  = self.view.frame.size.height;
    self.scrollView.contentSize = CGSizeMake(scrollWidth, scrollHeight);
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.bounces = NO;
    
    //CGFloat newContentOffsetX = (self.view.frame.size.width);
    //self.scrollView.contentOffset = CGPointMake(newContentOffsetX, 0);
    
    [[KAccountManager sharedManager] initLocationManager];
    [[KAccountManager sharedManager] refreshCurrentCoordinate];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

-(BOOL)shouldAutorotate {
    return NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:kThreadSeguePush]) {
        if(self.selectedThread) {
            ThreadViewController *threadViewController = (ThreadViewController *)segue.destinationViewController;
            threadViewController.thread = self.selectedThread;
        }
    }else if([[segue identifier] isEqual:kSelectRecipientSegueIdentifier]) {
        SelectRecipientViewController *selectRecipientController = (SelectRecipientViewController *)segue.destinationViewController;
        SocialViewController *socialViewController = (SocialViewController *)sender;
        selectRecipientController.currentUser = socialViewController.currentUser;
        selectRecipientController.post        = socialViewController.currentPost;
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)dismissAndPresentThread:(KThread *)thread {
    [self dismissViewControllerAnimated:NO completion:^{
        self.selectedThread = thread;
        [self performSegueWithIdentifier:kThreadSeguePush sender:self];
    }];
}

- (void)dismissAndPresentViewController:(UIViewController *)viewController {
    [self dismissViewControllerAnimated:NO completion:^{
        [self presentViewController:viewController animated:YES completion:nil];
    }];
}

- (BOOL)resignFirstResponder {
    return YES;
}

@end
