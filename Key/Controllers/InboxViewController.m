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
    [super viewDidLoad];
    [UIView setAnimationsEnabled:NO];
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

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SubtitleTableViewCell *cell = [self.threadsTableView dequeueReusableCellWithIdentifier:[self cellIdentifier] forIndexPath:indexPath];
    KThread *thread = (KThread *)[self objectForIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", thread.displayName];
    if(thread.latestMessage) cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", thread.latestMessage.text];
    cell.imageView.image = [self imageRead:thread.read];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
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
    dispatch_async([self.class sharedQueue], ^{
        KThread *thread = (KThread *)[self objectForIndexPath:indexPath];
        if(thread) {
            self.homeViewController.selectedThread = thread;
            dispatch_async(dispatch_get_main_queue(), ^{});
            [self.homeViewController performSegueWithIdentifier:kThreadSeguePush sender:self];
        }
    });
}

- (NSString *)cellIdentifier {
    return @"Messages";
}

- (HomeViewController *)homeViewController {
    return (HomeViewController *)self.parentViewController.parentViewController;
}

@end
