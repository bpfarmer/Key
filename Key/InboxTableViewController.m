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
}

- (void)addHeaderAndFooter {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, 300, 50)];
    UILabel *headerLabelView = [[UILabel alloc] initWithFrame:CGRectMake(25, 25, 200, 20)];
    headerLabelView.text = @"Messages";
    [headerView addSubview:headerLabelView];
    self.tableView.tableHeaderView = headerView;
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 100, 300, 50)];
    UIButton *newMessageButton = [[UIButton alloc] initWithFrame:CGRectMake(25, 25, 200, 20)];
    [newMessageButton addTarget:self action:@selector(newThread) forControlEvents:UIControlEventTouchUpInside];
    [newMessageButton setTitle:@"New Message" forState:UIControlStateNormal];
    [newMessageButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [footerView addSubview:newMessageButton];
    self.tableView.tableFooterView = footerView;
}

- (void) newThread {
    [self performSegueWithIdentifier:@"ShowThreadDetail" sender:self];
}

- (void) setupDatabaseView {
    [KYapDatabaseView registerThreadDatabaseView];
    _databaseConnection = [KStorageManager longLivedReadConnection];
    _threadMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[@"KInboxGroup"] view:@"KThreadDatabaseViewExtension"];
    
    [self.databaseConnection beginLongLivedReadTransaction];
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
        // One-time initialization
        [self.threadMappings updateWithTransaction:transaction];
    }];
    
    NSLog(@"SHOULD BE ROWS: %lu", [self.threadMappings numberOfItemsInAllGroups]);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:self.databaseConnection.database];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)yapDatabaseModified:(NSNotification *)notification {
    
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
    NSLog(@"SUPPOSED TO SAY: %@", [thread uniqueId]);
    cell.textLabel.text = [thread uniqueId];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
