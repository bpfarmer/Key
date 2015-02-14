//
//  InboxTableViewController.m
//  Key
//
//  Created by Loren on 2/5/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "InboxTableViewController.h"
#import "KUser.h"
#import "KAccountManager.h"
#import "KThread.h"
#import "KStorageManager.h"
#import "KYapDatabaseView.h"
#import "ThreadTableViewController.h"

static NSString *TableViewCellIdentifier = @"Threads";

YapDatabaseViewMappings *mappings;
YapDatabaseConnection *databaseConnection;

@interface InboxTableViewController ()

@property (nonatomic, strong) YapDatabaseConnection   *databaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *threadMappings;


@end

@implementation InboxTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewCellIdentifier];

    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    [self setupDatabaseView];
    
    [self addHeaderAndFooter];
    
    NSLog(@"DB Path: %@", [[KStorageManager sharedManager] dbPath]);
}

- (void)addHeaderAndFooter {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, 60)];
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 100, [UIScreen mainScreen].bounds.size.width, 50)];
    UILabel *headerLabelView = [[UILabel alloc] initWithFrame:CGRectMake(15, 25, [UIScreen mainScreen].bounds.size.width, 20)];
    headerLabelView.text = @"Messages";
    [headerLabelView sizeToFit];
    headerLabelView.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:headerLabelView];
    UIButton *newMessageButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 15, 150, 20)];
    [newMessageButton addTarget:self action:@selector(newThread) forControlEvents:UIControlEventTouchUpInside];
    [newMessageButton setTitle:@"New Message" forState:UIControlStateNormal];
    [newMessageButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [footerView addSubview:newMessageButton];
    
    [headerView setBackgroundColor:[UIColor whiteColor]];
    [footerView setBackgroundColor:[UIColor whiteColor]];
    self.tableView.tableHeaderView = headerView;
    self.tableView.tableFooterView = footerView;

}

- (void) newThread {
    [self performSegueWithIdentifier:@"ShowThreadDetail" sender:self];
}

- (void) goToThread:(KThread *)thread {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    ThreadTableViewController *threadView = [storyboard instantiateViewControllerWithIdentifier:@"ThreadTableViewController"];
    threadView.thread = thread;
    [self presentViewController:threadView animated:YES completion:nil];

}

- (void) setupDatabaseView {
    _databaseConnection = [[KStorageManager sharedManager] newDatabaseConnection];
    [self.databaseConnection beginLongLivedReadTransaction];
    _threadMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[@"KInboxGroup"] view:@"KThreadDatabaseViewExtension"];
    
    [self.databaseConnection beginLongLivedReadTransaction];
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
        [self.threadMappings updateWithTransaction:transaction];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:self.databaseConnection.database];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)yapDatabaseModified:(NSNotification *)notification {
    NSArray *notifications = [self.databaseConnection beginLongLivedReadTransaction];
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    
    [[self.databaseConnection ext:@"KThreadDatabaseViewExtensionName"] getSectionChanges:&sectionChanges
                                                                               rowChanges:&rowChanges
                                                                         forNotifications:notifications
                                                                             withMappings:self.threadMappings];
    
    if ([sectionChanges count] == 0 & [rowChanges count] == 0)
    {
        return;
    }
    
    [self.tableView beginUpdates];
    
    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges)
    {
        switch (sectionChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
        }
    }
    
    for (YapDatabaseViewRowChange *rowChange in rowChanges)
    {
        switch (rowChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.tableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.tableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove :
            {
                [self.tableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate :
            {
                [self.tableView reloadRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    
    [self.tableView endUpdates];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    return [self.threadMappings numberOfSections];
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section
{
    return [self.threadMappings numberOfItemsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block KThread *thread = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        thread = [[transaction extension:@"KThreadDatabaseViewExtension"] objectAtIndexPath:indexPath withMappings:self.threadMappings];
    }];
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TableViewCellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = [thread uniqueId];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    __block KThread *thread = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        thread = [[transaction extension:@"KThreadDatabaseViewExtension"] objectAtIndexPath:indexPath withMappings:self.threadMappings];
    }];
    if(thread) [self goToThread:thread];
}

@end
