//
//  ContactViewController.m
//  Key
//
//  Created by Brendan Farmer on 3/18/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ContactViewController.h"
#import "KUser.h"
#import "KAccountManager.h"
#import "KThread.h"
#import "KStorageManager.h"
#import "KYapDatabaseView.h"
#import "KMessage.h"
#import "FreeKeyNetworkManager.h"
#import "CollapsingFutures.h"

static NSString *TableViewCellIdentifier = @"Threads";

YapDatabaseViewMappings *mappings;
YapDatabaseConnection *databaseConnection;

@interface ContactViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) IBOutlet UITableView *contactsTableView;
@property (nonatomic, strong) IBOutlet UITextField *contactTextField;
@property (nonatomic, strong) YapDatabaseConnection   *databaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *contactMappings;
@property (nonatomic) KUser *currentUser;
@end

@implementation ContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentUser = [KAccountManager sharedManager].user;
    
    self.contactsTableView.dataSource = self;
    self.contactsTableView.delegate = self;
    [self.contactsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewCellIdentifier];
    
    [self setupDatabaseView];
}

- (void) setupDatabaseView {
    _databaseConnection = [[KStorageManager sharedManager] newDatabaseConnection];
    [self.databaseConnection beginLongLivedReadTransaction];
    _contactMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[@"KContactGroup"] view:KContactDatabaseViewName];
    
    [self.databaseConnection beginLongLivedReadTransaction];
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
        [self.contactMappings updateWithTransaction:transaction];
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
    
    [[self.databaseConnection ext:KContactDatabaseViewName] getSectionChanges:&sectionChanges
                                                                  rowChanges:&rowChanges
                                                            forNotifications:notifications
                                                                withMappings:self.contactMappings];
    
    if ([sectionChanges count] == 0 & [rowChanges count] == 0)
    {
        return;
    }
    
    [self.contactsTableView beginUpdates];
    
    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges)
    {
        switch (sectionChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.contactsTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                                     withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.contactsTableView insertSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
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
                [self.contactsTableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                             withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.contactsTableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                             withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove :
            {
                [self.contactsTableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                             withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.contactsTableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                             withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate :
            {
                [self.contactsTableView reloadRowsAtIndexPaths:@[ rowChange.indexPath ]
                                             withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    
    [self.contactsTableView endUpdates];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    return [self.contactMappings numberOfSections];
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section
{
    return [self.contactMappings numberOfItemsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block KUser *user = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        user = (KUser *)[[transaction extension:KContactDatabaseViewName] objectAtIndexPath:indexPath withMappings:self.contactMappings];
    }];
    
    UITableViewCell *cell = [self.contactsTableView dequeueReusableCellWithIdentifier:TableViewCellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = [user displayName];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    __block KUser *user = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        user = [[transaction extension:KContactDatabaseViewName] objectAtIndexPath:indexPath withMappings:self.contactMappings];
    }];
    //if(thread) [self goToThread:thread];
}

- (IBAction)addContact:(id)sender {
    if(![self.contactTextField.text isEqualToString:@""] &&
       ![self.contactTextField.text isEqualToString:self.currentUser.username]) {
        KUser *targetUser = [KUser fetchObjectWithUsername:[self.contactTextField.text lowercaseString]];
        if(!targetUser) {
            TOCFuture *futureUser = [KUser asyncRetrieveWithUsername:[self.contactTextField.text lowercaseString]];
            
            [futureUser catchDo:^(id failure) {
                NSLog(@"ERROR: %@", failure);
            }];
            
            [futureUser thenDo:^(KUser *user) {
                // TODO: create added contact notification and send?
            }];
        }
        self.contactTextField.text = @"";
    }
}

@end
