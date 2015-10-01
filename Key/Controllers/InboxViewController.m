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
#import "PushManager.h"
#import "HomeViewController.h"
#import "DismissAndPresentProtocol.h"
#import "SelectRecipientViewController.h"
#import "KDevice.h"
#import "SubtitleTableViewCell.h"

@interface InboxViewController ()
@property (nonatomic, strong) IBOutlet UITableView *threadsTableView;
@end

@implementation InboxViewController

- (void)viewDidLoad {
    self.tableView = self.threadsTableView;
    self.sectionCriteria = @[@{@"class" : @"KThread",
                               @"criteria" : @{}}];
    self.sortedByProperty = @"updatedAt";
    self.sortDescending = YES;
    [super viewDidLoad];
    [UIView setAnimationsEnabled:NO];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)viewDidAppear:(BOOL)animated {
    [[KAccountManager sharedManager].user asyncGetFeed];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)didPressNewMessage:(id)sender {
    self.homeViewController.selectedThread = nil;
    [self.homeViewController performSegueWithIdentifier:kThreadSeguePush sender:self];
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SubtitleTableViewCell *cell = [self.threadsTableView dequeueReusableCellWithIdentifier:[self cellIdentifier] forIndexPath:indexPath];
    KThread *thread = (KThread *)[self objectForIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", thread.displayName];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", thread.latestMessageText];
    if(!thread.read) [cell addUnreadImage];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}

- (IBAction)logout:(id)sender {
    [[KAccountManager sharedManager] setUser:nil];
    [[KStorageManager sharedManager] resignDatabase];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    LoginViewController *loginView = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    [[UIApplication sharedApplication].keyWindow setRootViewController:loginView];
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    KThread *thread = (KThread *)[self objectForIndexPath:indexPath];
    if(thread) {
        self.homeViewController.selectedThread = thread;
        [self.homeViewController performSegueWithIdentifier:kThreadSeguePush sender:self];
    }
}

- (NSString *)cellIdentifier {
    return @"Messages";
}

- (HomeViewController *)homeViewController {
    return (HomeViewController *)self.parentViewController.parentViewController;
}

@end
