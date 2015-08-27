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
@property (strong, nonatomic) ShareViewController *shareViewController;

@end


@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    ContentViewController *contentVC = [ContentViewController new];
    [[NSBundle mainBundle] loadNibNamed:@"ContentView" owner:contentVC options:nil];
    
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.bounces = NO;
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.scrollView];
    
    self.shareViewController = [[ShareViewController alloc] initWithNibName:@"ShareView" bundle:nil];
    [self addChildViewController:self.shareViewController];
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width * 2, [UIScreen mainScreen].bounds.size.height)];
    [self.scrollView addSubview:self.contentView];
    
    [self addChildViewController:contentVC];
    [self.contentView addSubview:contentVC.contentTC.view];
    [contentVC didMoveToParentViewController:self];
    [self addChildViewController:contentVC.contentTC];
    
    [self.contentView addSubview:self.shareViewController.view];
    
    [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v]|" options:0 metrics:nil views:@{@"v" : self.contentView}]];
    [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[v]|" options:0 metrics:nil views:@{@"v" : self.contentView}]];
    
    self.scrollView.contentSize = CGSizeMake(self.contentView.frame.size.width, self.contentView.frame.size.height);
    
    [[KAccountManager sharedManager] initLocationManager];
    [[KAccountManager sharedManager] refreshCurrentCoordinate];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(self.shareViewController) {
        if(!CGRectIntersectsRect(self.scrollView.bounds, self.shareViewController.view.bounds)) {
            [self.shareViewController cameraOn];
        }else {
            [self.shareViewController cameraOff];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadInputViews];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

-(BOOL)shouldAutorotate {
    return NO;
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

@end
