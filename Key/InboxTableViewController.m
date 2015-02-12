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
    
    self.tableView =
    [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    
    [self.tableView registerClass:[UITableViewCell class]
             forCellReuseIdentifier:TableViewCellIdentifier];
        
    /* Make sure our table view resizes correctly */
    self.tableView.autoresizingMask =
                UIViewAutoresizingFlexibleWidth |
                UIViewAutoresizingFlexibleHeight;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    NSLog(@"%lu", (unsigned long)[[KStorageManager sharedManager] numberOfKeysInCollection:[KThread collection]]);
    NSLog(@"INBOX TABLE VIEW DB PATH: %@", [[KStorageManager sharedManager] dbPath]);
    NSLog(@"INBOX TABLE VIEW ACCOUNT MANAGER: %@", [[KAccountManager sharedManager] uniqueId]);
    [self setupDatabaseView];
    
}

- (void) setupDatabaseView {
    [KYapDatabaseView registerThreadDatabaseView];
    _databaseConnection = [KStorageManager longLivedReadConnection];
    [databaseConnection beginLongLivedReadTransaction];
    
    _threadMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[] view:@"KThreadDatabaseViewExtension"];
    
    // We can do all kinds of cool stuff with the mappings object.
    // For example, we could say we only want to display the top 20 in each genre.
    // This will be covered later.
    //
    // Now initialize the mappings object.
    // It will fetch and cache the counts per group/section.
    
    [databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
        // One-time initialization
        [mappings updateWithTransaction:transaction];
    }];
    
    // And register for notifications when the database changes.
    // Our method will be invoked on the main-thread,
    // and will allow us to move our stable data-source from our existing state to an updated state.
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:databaseConnection.database];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)yapDatabaseModified:(NSNotification *)notification {
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([tableView isEqual:self.tableView]){
        return [mappings numberOfSections];
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([tableView isEqual:self.tableView]){
        return [mappings numberOfItemsInSection:section];
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    __block KMessage *message = nil;
    [databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        message = [[transaction extension:@"KInboxGroup"] objectAtIndexPath:indexPath withMappings:mappings];
    }];
    
    return [self cellForMessage:message];
}

- (UITableViewCell *)cellForMessage:(KMessage *)message {
    return nil;
}

- (UILabel *) newLabelWithTitle:(NSString *)paramTitle{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = paramTitle;
    label.backgroundColor = [UIColor clearColor];
    [label sizeToFit];
    return label;
}

- (UIView *) tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section{
    if (section == 0){
        return [self newLabelWithTitle:@"Section 1 Header"];
    }
    return nil; }

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section == 0){
        return [self newLabelWithTitle:@"Section 1 Footer"];
    }
    return nil; }


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
