//
//  InboxViewController.m
//  Key
//
//  Created by Brendan Farmer on 4/16/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "InboxViewController.h"
#import "KUser.h"
#import "KAccountManager.h"
#import "KThread.h"
#import "KStorageManager.h"
#import "KMessage.h"
#import "ThreadViewController.h"
#import "LoginViewController.h"
#import "FreeKeyNetworkManager.h"
#import "PushManager.h"
#import "HomeViewController.h"

static NSString *TableViewCellIdentifier = @"Messages";

@interface InboxViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) IBOutlet UITableView *threadsTableView;
@end


@implementation InboxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[KAccountManager sharedManager].user asyncGetFeed];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)newMessage:(id)sender {
    [self.parentViewController performSegueWithIdentifier:kThreadSeguePush sender:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section
{
    return 0;//[self.threadMappings numberOfItemsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (IBAction)pushContacts:(id)sender {
    [self.parentViewController performSegueWithIdentifier:kContactsSeguePush sender:self];
}

- (IBAction)logout:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    LoginViewController *loginView = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    [self presentViewController:loginView animated:YES completion:nil];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    __block KThread *thread = nil;
    if(thread) {
        self.selectedThread = thread;
        [self.parentViewController performSegueWithIdentifier:kThreadSeguePush sender:self];
    }
}

@end
