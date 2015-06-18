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
#import "KYapDatabaseView.h"
#import "KMessage.h"
#import "KPost.h"
#import "ThreadViewController.h"
#import "LoginViewController.h"
#import "FreeKeyNetworkManager.h"
#import "PushManager.h"
#import "InboxViewController.h"
#import "SocialViewController.h"
#import "ShareViewController.h"
#import "SelectRecipientViewController.h"

static NSString *TableViewCellIdentifier = @"Threads";
static NSString *kThreadSeguePush        = @"threadSeguePush";
static NSString *kShareViewSegue         = @"shareViewSegue";

YapDatabaseViewMappings *mappings;
YapDatabaseConnection *databaseConnection;

@interface HomeViewController ()

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;

@end


@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    InboxViewController *inboxViewController = [[InboxViewController alloc] initWithNibName:@"InboxView" bundle:nil];
    [self addChildViewController:inboxViewController];
    [self.scrollView addSubview:inboxViewController.view];
    [inboxViewController didMoveToParentViewController:self];
    
    ShareViewController *shareViewController = [[ShareViewController alloc] initWithNibName:@"ShareView" bundle:nil];
    [self addChildViewController:shareViewController];
    [self.scrollView addSubview:shareViewController.view];
    [inboxViewController didMoveToParentViewController:self];
    
    SocialViewController *socialViewController = [[SocialViewController alloc] initWithNibName:@"SocialView" bundle:nil];
    [self addChildViewController:socialViewController];
    [self.scrollView addSubview:socialViewController.view];
    [inboxViewController didMoveToParentViewController:self];
    
    CGRect adminFrame = inboxViewController.view.frame;
    adminFrame.origin.x = adminFrame.size.width;
    shareViewController.view.frame = adminFrame;
    
    CGRect shareFrame = shareViewController.view.frame;
    shareFrame.origin.x = 2*shareFrame.size.width;
    socialViewController.view.frame = shareFrame;
    
    
    // 4) Finally set the size of the scroll view that contains the frames
    CGFloat scrollWidth  = 3 * self.view.frame.size.width;
    CGFloat scrollHeight  = self.view.frame.size.height;
    self.scrollView.contentSize = CGSizeMake(scrollWidth, scrollHeight);
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:kThreadSeguePush]) {
        InboxViewController *inboxViewController = (InboxViewController *)sender;
        if(inboxViewController.selectedThread) {
            ThreadViewController *threadViewController = (ThreadViewController *)segue.destinationViewController;
            threadViewController.thread = inboxViewController.selectedThread;
        }
    }else if([[segue identifier] isEqual:KSelectRecipientSegueIdentifier]) {
        SelectRecipientViewController *selectRecipientController = (SelectRecipientViewController *)segue.destinationViewController;
        SocialViewController *socialViewController = (SocialViewController *)sender;
        selectRecipientController.currentUser = socialViewController.currentUser;
        selectRecipientController.post        = socialViewController.currentPost;
        NSLog(@"POST IN DEST CONTROLLER: %@", selectRecipientController.post.uniqueId);
    }
}

@end
