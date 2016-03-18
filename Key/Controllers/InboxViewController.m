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
#import "DatabaseDataSource.h"

@interface InboxViewController ()
@property (nonatomic, strong) IBOutlet UITableView *threadsTableView;
@end

@implementation InboxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [UIView setAnimationsEnabled:NO];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    DatabaseDataSource *dataSource = [[DatabaseDataSource alloc] initWithSectionData:[self tableData]
                                                                      cellIdentifier:[self cellIdentifier]
                                                                           tableView:self.threadsTableView
                                                                  configureCellBlock:[self configureCellBlock]
                                                                sectionCriteriaBlock:[self sectionCriteriaBlock]
                                                                           sortBlock:[self sortBlock]];
    [dataSource registerForUpdatesFromClasses:@[@"KUser"]];
    self.threadsTableView.dataSource = dataSource;
}

- (NSArray *)tableData {
    return [KThread all];
}

- (NSString *)cellIdentifier {
    return @"Threads";
}

- (NSComparisonResult (^)(KDatabaseObject*, KDatabaseObject*))sortBlock {
    return ^(KDatabaseObject *object1, KDatabaseObject *object2) {
        KThread *thread1 = (KThread *)object1;
        KThread *thread2 = (KThread *)object2;
        if(!thread1.read) {
            return NSOrderedAscending;
        }else if(!thread2.read) {
            return NSOrderedDescending;
        }else {
            return [thread1.updatedAt compare:thread2.updatedAt];
        }
    };
}

- (BOOL (^)(KDatabaseObject*, NSUInteger))sectionCriteriaBlock {
    return ^(KDatabaseObject *object, NSUInteger sectionId) {
        return [object isKindOfClass:[KThread class]];
    };
}

- (UITableViewCell* (^)(UITableViewCell*, KDatabaseObject*))configureCellBlock {
    return ^(UITableViewCell *cell, KDatabaseObject *object) {
        return cell;
    };
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
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

- (IBAction)logout:(id)sender {
    [[KAccountManager sharedManager] setUser:nil];
    [[KStorageManager sharedManager] resignDatabase];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    LoginViewController *loginView = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    [[UIApplication sharedApplication].keyWindow setRootViewController:loginView];
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    KThread *thread = (KThread *)[KThread new];
    if(thread) {
        self.homeViewController.selectedThread = thread;
        [self.homeViewController performSegueWithIdentifier:kThreadSeguePush sender:self];
    }
}

- (HomeViewController *)homeViewController {
    return (HomeViewController *)self.parentViewController.parentViewController;
}

@end
