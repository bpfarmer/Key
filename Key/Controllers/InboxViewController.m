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
#import "DismissAndPresentProtocol.h"
#import "SelectRecipientViewController.h"

static NSString *TableViewCellIdentifier = @"Messages";

@interface InboxViewController () <UITableViewDataSource, UITableViewDelegate, DismissAndPresentProtocol>
@property (nonatomic, strong) IBOutlet UITableView *threadsTableView;
@property (nonatomic, strong) NSArray *threads;
@end


@implementation InboxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[KAccountManager sharedManager].user asyncGetFeed];
    self.threads = [KThread all];
    NSLog(@"THREAD COUNT: %u", self.threads.count);
    
    self.threadsTableView.delegate = self;
    self.threadsTableView.dataSource = self;
    
    [self.threadsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewCellIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(databaseModified:)
                                                 name:[KThread notificationChannel]
                                               object:nil];
}

- (void)databaseModified:(NSNotification *)notification {
    if([[notification object] isKindOfClass:[KThread class]]) {
        for(KThread *thread in self.threads) if([thread.uniqueId isEqualToString:((KThread *)notification.object).uniqueId]) return;
        NSMutableArray *threads = [[NSMutableArray alloc] initWithArray:self.threads];
        [threads addObject:[notification object]];
        self.threads = [[NSArray alloc] initWithArray:threads];
        [self.threadsTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(self.threads.count - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)didPressNewMessage:(id)sender {
    SelectRecipientViewController *selectRecipientView = [[SelectRecipientViewController alloc] initWithNibName:@"SelectRecipientsView" bundle:nil];
    selectRecipientView.desiredObject = kSelectRecipientsForMessage;
    selectRecipientView.delegate = self;
    [self.parentViewController presentViewController:selectRecipientView animated:YES completion:nil];
}

- (IBAction)didPressContacts:(id)sender {
    [self.parentViewController performSegueWithIdentifier:kContactsSeguePush sender:self];
}

- (void)dismissAndPresentViewController:(UIViewController *)viewController {
    [self dismissViewControllerAnimated:NO completion:^{
        [self presentViewController:viewController animated:NO completion:nil];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender {
    return 1;
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section {
    NSLog(@"THREAD COUNT FOR SECTION %u", self.threads.count);
    return self.threads.count;
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.threadsTableView dequeueReusableCellWithIdentifier:TableViewCellIdentifier forIndexPath:indexPath];
    KThread *thread = self.threads[indexPath.row];
    NSString *read = @"";
    if(!thread.read) {
        read = @" - UNREAD";
    }
    NSLog(@"THREAD ID: %@", thread.uniqueId);
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", thread.displayName, read];
    //[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}

- (IBAction)logout:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    LoginViewController *loginView = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    [self presentViewController:loginView animated:YES completion:nil];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    KThread *thread = self.threads[indexPath.row];
    if(thread) {
        ThreadViewController *threadViewController = [[ThreadViewController alloc] initWithNibName:@"ThreadView" bundle:nil];
        threadViewController.thread = thread;
        [self.parentViewController presentViewController:threadViewController animated:NO completion:nil];
    }
}

@end
