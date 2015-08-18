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
    
    // 4) Finally set the size of the scroll view that contains the frames
    CGFloat scrollWidth  = 2 * self.view.frame.size.width;
    CGFloat scrollHeight = self.view.frame.size.height;
    self.view.frame = CGRectMake(0, 0, scrollWidth, scrollHeight);
    self.scrollView.frame = self.view.frame;
    self.scrollView.contentSize = self.view.frame.size;
    NSLog(@"INITIAL FRAME: %f %f %f %f", self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    
    [self addChildViewController:contentVC];
    [self.scrollView addSubview:contentVC.contentTC.view];
    [contentVC didMoveToParentViewController:self];
    [self addChildViewController:contentVC.contentTC];
    
    NSLog(@"CONTENT FRAME: %f %f %f %f", contentVC.view.frame.origin.x, contentVC.view.frame.origin.y, contentVC.view.frame.size.width, contentVC.view.frame.size.height);
    
    CGRect adminFrame = contentVC.view.frame;
    adminFrame.origin.x = adminFrame.size.width;
    
    NSLog(@"SCROLL FRAME: %f %f %f %f", self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
    //self.scrollView.frame = CGRectMake(0, 0, scrollWidth, scrollHeight);
    self.scrollView.contentSize = CGSizeMake(scrollWidth, scrollHeight);
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.bounces = NO;
    
    ShareViewController *shareViewController = [[ShareViewController alloc] initWithNibName:@"ShareView" bundle:nil];
    [self addChildViewController:shareViewController];
    [self.scrollView addSubview:shareViewController.view];
    
    CGRect shareFrame = CGRectMake(adminFrame.size.width, 0, adminFrame.size.width, adminFrame.size.height);
    shareViewController.view.frame = shareFrame;
    
    CGFloat newContentOffsetX = (self.view.frame.size.width);
    self.scrollView.contentOffset = CGPointMake(newContentOffsetX, 0);
    
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
