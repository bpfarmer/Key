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
@property (nonatomic, strong) KUser *currentUser;

@end

@implementation ThreadTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentUser = [KAccountManager currentUser];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewCellIdentifier];

    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if (self.thread) {
        [self setupDatabaseView];
    }
    
    [self addHeaderAndFooter];
}

- (void)addHeaderAndFooter {
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
    [submitButton addTarget:self action:@selector(createMessage) forControlEvents:UIControlEventTouchUpInside];
    [submitButton setTitle:@"Send" forState:UIControlStateNormal];
    [submitButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [footerView addSubview:submitButton];
    [headerView setBackgroundColor:[UIColor whiteColor]];
    [footerView setBackgroundColor:[UIColor whiteColor]];
    self.tableView.tableHeaderView = headerView;
    self.tableView.tableFooterView = footerView;
}

- (void) createMessage {
    if (!self.thread) {
        NSArray *usernames = [self.recipientTextField.text componentsSeparatedByString:@", "];
        NSMutableArray *recipientIds = [NSMutableArray arrayWithObjects:self.currentUser.uniqueId, nil];
        for (NSString *username in usernames) {
            [recipientIds addObject:username];
        };
        [[KStorageManager sharedManager] setObject:self.thread forKey:[self.thread uniqueId] inCollection:[[self.thread class] collection]];
        self.thread = [[KThread alloc] initWithUsers:recipientIds];
        [self setupDatabaseView];
    }
    NSLog(@"THREAD ID: %@", [self.thread uniqueId]);
    KMessage *message = [[KMessage alloc] initFrom:self.currentUser.uniqueId threadId:[self.thread uniqueId] body:self.messageTextField.text];
    [[KStorageManager sharedManager] setObject:message forKey:[message uniqueId] inCollection:[[message class] collection]];
    NSLog(@"MESSAGE THREAD ID: %@", [[[KStorageManager sharedManager] objectForKey:[message uniqueId] inCollection:[[message class] collection]] threadId]);
    NSLog(@"WILL EVENTUALLY SAY: %@", message.body);
    NSLog(@"ONLY GOT ONE KEY %@", [message uniqueId]);
    NSLog(@"COLLECTION: %@", [[message class] collection]);
    NSLog(@"SHOULD BE MESSAGES: %lu", (unsigned long)[self.messageMappings numberOfItemsInGroup:self.thread.uniqueId]);
}

- (void) setupDatabaseView {
    [KYapDatabaseView registerMessageDatabaseView];
    self.readDatabaseConnection = [KStorageManager longLivedReadConnection];
    self.messageMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[self.thread.uniqueId] view:@"KMessageDatabaseViewExtensionName"];
    
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
    NSLog(@"Supposed to have updated...");
    NSArray *notifications = [self.readDatabaseConnection beginLongLivedReadTransaction];
    
    // Process the notification(s),
    // and get the change-set(s) as applies to my view and mappings configuration.
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    
    [[self.readDatabaseConnection ext:@"KMessageDatabaseViewExtensionName"] getSectionChanges:&sectionChanges
                                                  rowChanges:&rowChanges
                                            forNotifications:notifications
                                                withMappings:self.messageMappings];
    
    
    if ([sectionChanges count] == 0 & [rowChanges count] == 0)
    {
        // Nothing has changed that affects our tableView
        NSLog(@"THIS IS BAD");
        return;
    }
    
    // Familiar with NSFetchedResultsController?
    // Then this should look pretty familiar
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
    return 1;//[self.messageMappings numberOfSections];
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section
{
    return [self.messageMappings numberOfItemsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block KMessage *message;
    [self.readDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        message = (KMessage *)[[transaction extension:@"KMessageDatabaseViewExtensionName"] objectAtIndexPath:indexPath withMappings:self.messageMappings];
    }];
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TableViewCellIdentifier forIndexPath:indexPath];
    NSLog(@"SUPPOSED TO SAY: %@", message.body);
    cell.textLabel.text = message.body;
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
