//
//  ContentTabBarController.m
//  Key
//
//  Created by Brendan Farmer on 7/16/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ContentTabBarController.h"
#import "InboxViewController.h"
#import "SocialViewController.h"
#import "ContactViewController.h"
#import "ContentViewController.h"

@implementation ContentTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    InboxViewController *inboxVC = [[InboxViewController alloc] initWithNibName:@"InboxView" bundle:nil];
    SocialViewController *socialVC = [[SocialViewController alloc] initWithNibName:@"SocialView" bundle:nil];
    ContactViewController *contactVC = [[ContactViewController alloc] initWithNibName:@"ContactView" bundle:nil];
    [self setViewControllers:@[inboxVC, socialVC, contactVC]];
    inboxVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Inbox" image:nil selectedImage:nil];
    [inboxVC.tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Helvetica" size:18.0], NSFontAttributeName, nil] forState:UIControlStateNormal];
    socialVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Shared" image:nil selectedImage:nil];
    [socialVC.tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Helvetica" size:18.0], NSFontAttributeName, nil] forState:UIControlStateNormal];
    contactVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"People" image:nil selectedImage:nil];
    [contactVC.tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Helvetica" size:18.0], NSFontAttributeName, nil] forState:UIControlStateNormal];
    CGRect frame = self.tabBar.frame;
    frame.origin = CGPointMake(0, 0);
    self.tabBar.frame = frame;
    [self addChildViewController:inboxVC];
    [self addChildViewController:socialVC];
    [self addChildViewController:contactVC];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
