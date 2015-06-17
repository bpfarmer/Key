//
//  SelectRecipientViewController.m
//  Key
//
//  Created by Brendan Farmer on 4/29/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "SelectRecipientViewController.h"
#import "KStorageManager.h"
#import "KAccountManager.h"
#import "KYapDatabaseView.h"
#import "KUser.h"
#import "KPost.h"
#import "FreeKey.h"
#import "FreeKeyNetworkManager.h"

static NSString *TableViewCellIdentifier = @"Threads";

@interface SelectRecipientViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *contactsTableView;
@property (nonatomic, strong) YapDatabaseConnection   *databaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *contactMappings;
@property (nonatomic) NSArray *selectedRecipients;

@end

@implementation SelectRecipientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
            case YapDatabaseViewChangeUpdate :
            {
                break;
            }
            case YapDatabaseViewChangeMove :
            {
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
    
    if(user) {
        NSMutableArray *mutableSelected = [[NSMutableArray alloc] initWithArray:self.selectedRecipients];
        [mutableSelected addObject:user];
        self.selectedRecipients = mutableSelected;
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    __block KUser *user = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        user = [[transaction extension:KContactDatabaseViewName] objectAtIndexPath:indexPath withMappings:self.contactMappings];
    }];
    
    if(user) {
        NSMutableArray *mutableSelected = [[NSMutableArray alloc] initWithArray:self.selectedRecipients];
        [mutableSelected removeObject:user];
        self.selectedRecipients = mutableSelected;
    }
}

- (IBAction)sendToRecipients:(id)sender {
    NSLog(@"HERE");
    [self.selectedRecipients enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        dispatch_queue_t queue = dispatch_queue_create([kEncryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
        dispatch_async(queue, ^{
            KUser *user = (KUser *)obj;
            //[[FreeKeyNetworkManager sharedManager] enqueueEncryptableObject:self.post
            //                                                      localUser:self.currentUser
            //                                                     remoteUser:user];
        });
    }];
    
    [self.post save];
}

@end
