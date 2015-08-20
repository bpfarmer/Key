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

static NSString *TableViewCellIdentifier = @"Messages";

@interface InboxViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) IBOutlet UITableView *threadsTableView;
@property (nonatomic, strong) NSArray *threads;
@end

@implementation InboxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.threads = [KThread inbox];
    self.threadsTableView.delegate = self;
    self.threadsTableView.dataSource = self;
    
    self.threadsTableView.scrollEnabled = YES;
    
    [self.threadsTableView registerClass:[SubtitleTableViewCell class] forCellReuseIdentifier:TableViewCellIdentifier];
    
    [UIView setAnimationsEnabled:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(databaseModified:)
                                                 name:[KThread notificationChannel]
                                               object:nil];
}

- (void)databaseModified:(NSNotification *)notification {
    if([notification.object isKindOfClass:[KThread class]]) {
        KThread *newThread = (KThread *)notification.object;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *threads = [[NSMutableArray alloc] initWithArray:self.threads];
            NSUInteger updatedIndex = -1;
            for(KThread *thread in threads)
                if([thread.uniqueId isEqualToString:newThread.uniqueId]) {
                    updatedIndex = [threads indexOfObject:thread];
                }
            if(updatedIndex == -1) {
                [threads insertObject:newThread atIndex:0];
                NSArray *newThreads = [threads copy];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(newThreads.count > self.threads.count) {
                        self.threads = [newThreads copy];
                        [self.threadsTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(0) inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                });
            }else {
                [threads removeObjectAtIndex:updatedIndex];
                NSArray *newThreads = [threads copy];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.threads = newThreads;
                    [self.threadsTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(updatedIndex) inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                    NSMutableArray *updatedThreads = [[NSMutableArray alloc] initWithArray:self.threads];
                    [updatedThreads insertObject:newThread atIndex:0];
                    self.threads = [updatedThreads copy];
                    [self.threadsTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                });
            }
        });
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)viewDidAppear:(BOOL)animated {
    [[KAccountManager sharedManager].user asyncGetFeed];
    [self.threadsTableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)didPressNewMessage:(id)sender {
    SelectRecipientViewController *selectRecipientView = [[SelectRecipientViewController alloc] initWithNibName:@"SelectRecipientsView" bundle:nil];
    selectRecipientView.desiredObject = kSelectRecipientsForMessage;
    selectRecipientView.delegate = self.homeViewController;
    [self.homeViewController presentViewController:selectRecipientView animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender {
    return 1;
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section {
    return self.threads.count;
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SubtitleTableViewCell *cell = [self.threadsTableView dequeueReusableCellWithIdentifier:TableViewCellIdentifier forIndexPath:indexPath];
    KThread *thread = self.threads[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", thread.displayName];
    if(thread.latestMessage) cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", thread.latestMessage.text];
    cell.imageView.image = [self imageRead:thread.read];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    NSLog(@"THREAD LAST MESSAGE AT: %@", thread.lastMessageAt);
    return cell;
}

- (UIImage *)imageRead:(BOOL)read {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(7.f, 7.f), NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    CGRect rect = CGRectMake(0, 0, 7, 7);
   
    if(!read) CGContextSetFillColorWithColor(ctx, self.view.tintColor.CGColor);
    else  CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillEllipseInRect(ctx, rect);
    
    CGContextRestoreGState(ctx);
    UIImage *blueCircle = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return blueCircle;
}

- (IBAction)logout:(id)sender {
    [[KAccountManager sharedManager] setUser:nil];
    [[KStorageManager sharedManager] resignDatabase];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    LoginViewController *loginView = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    [self presentViewController:loginView animated:YES completion:nil];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    KThread *thread = self.threads[indexPath.row];
    if(thread) {
        self.homeViewController.selectedThread = thread;
        dispatch_async(dispatch_get_main_queue(), ^{});
        [self.homeViewController performSegueWithIdentifier:kThreadSeguePush sender:self];
    }
}

- (HomeViewController *)homeViewController {
    return (HomeViewController *)self.parentViewController.parentViewController;
}

@end
