//
//  ThreadTableViewController.m
//  Key
//
//  Created by Loren on 2/5/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ThreadTableViewController.h"
#import "KUser.h"
#import "KAccountManager.h"
#import "KThread.h"
#import "KStorageManager.h"
#import "KMessage.h"
#import "KYapDatabaseView.h"

static NSString *TableViewCellIdentifier = @"Messages";

@interface ThreadTableViewController ()

@property (nonatomic, retain) KThread *thread;
@property (nonatomic, strong) YapDatabaseConnection   *editDatabaseConnection;
@property (nonatomic, strong) YapDatabaseConnection   *readDatabaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *messageMappings;
@property (nonatomic, strong) UITextField *recipientTextField;
@property (nonatomic, strong) UITextField *messageTextField;
@property (nonatomic) BOOL fetchingUsernames;
@property (nonatomic, strong) NSArray *recipients;

@end

@implementation ThreadTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView =
    [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewCellIdentifier];
    
    /* Make sure our table view resizes correctly */
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self setupDatabaseView];
    
    [self addHeaderAndFooter];
}

- (void)addHeaderAndFooter {
    NSLog(@"THREAD VALUE: %@", self.thread);
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, 300, 80)];
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 100, 300, 80)];
    
    if (!self.thread) {
        self.recipientTextField = [[UITextField alloc] initWithFrame:CGRectMake(30, 25, 200, 30)];
        [self.recipientTextField setBorderStyle:UITextBorderStyleRoundedRect];
        [headerView addSubview:self.recipientTextField];
    }else {
        UILabel *headerLabelView = [[UILabel alloc] initWithFrame:CGRectMake(25, 25, 200, 20)];
        headerLabelView.text = @"Thread";
        [headerView addSubview:headerLabelView];
    }
    self.messageTextField = [[UITextField alloc] initWithFrame:CGRectMake(30, 25, 200, 30)];
    [self.messageTextField setBorderStyle:UITextBorderStyleRoundedRect];
    [footerView addSubview:self.messageTextField];
    UIButton *submitButton = [[UIButton alloc] initWithFrame:CGRectMake(240, 25, 70, 30)];
    [submitButton addTarget:self action:@selector(createThread) forControlEvents:UIControlEventTouchUpInside];
    [submitButton setTitle:@"Send" forState:UIControlStateNormal];
    [submitButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [footerView addSubview:submitButton];
    [headerView setBackgroundColor:[UIColor whiteColor]];
    [footerView setBackgroundColor:[UIColor whiteColor]];
    self.tableView.tableHeaderView = headerView;
    self.tableView.tableFooterView = footerView;
}

- (void) createThread {
    
}

- (void) setupDatabaseView {
    [KYapDatabaseView registerThreadDatabaseView];
    self.readDatabaseConnection = [KStorageManager longLivedReadConnection];
    self.messageMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[@"KInboxGroup"] view:@"KMessageDatabaseViewExtension"];
    
    [self.readDatabaseConnection beginLongLivedReadTransaction];
    [self.readDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
        [self.messageMappings updateWithTransaction:transaction];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:self.readDatabaseConnection.database];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)yapDatabaseModified:(NSNotification *)notification {
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    return [self.messageMappings numberOfSections];
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section
{
    return [self.messageMappings numberOfItemsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block KMessage *message = nil;
    [self.readDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        message = [[transaction extension:@"KMessageDatabaseViewExtension"] objectAtIndexPath:indexPath withMappings:self.messageMappings];
    }];
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TableViewCellIdentifier forIndexPath:indexPath];
    NSLog(@"SUPPOSED TO SAY: %@", [message uniqueId]);
    cell.textLabel.text = [message uniqueId];
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
