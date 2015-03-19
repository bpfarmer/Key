//
//  HomeViewController.m
//  Key
//
//  Created by Brendan Farmer on 3/18/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "HomeViewController.h"
#import "KUser.h"
#import "KAccountManager.h"
#import "KThread.h"
#import "KStorageManager.h"
#import "KYapDatabaseView.h"
#import "ThreadTableViewController.h"

static NSString *TableViewCellIdentifier = @"Threads";

YapDatabaseViewMappings *mappings;
YapDatabaseConnection *databaseConnection;

@interface HomeViewController () <UITableViewDataSource>
@property (nonatomic, strong) IBOutlet UITableView *threadsTableView;
@property (nonatomic, strong) YapDatabaseConnection   *databaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *threadMappings;
@end


@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.threadsTableView.dataSource = self;
    [self.threadsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewCellIdentifier];
    
    [self setupDatabaseView];
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
    
    [self.threadsTableView beginUpdates];
    
    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges)
    {
        switch (sectionChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.threadsTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.threadsTableView insertSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
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
                [self.threadsTableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.threadsTableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove :
            {
                [self.threadsTableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.threadsTableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate :
            {
                [self.threadsTableView reloadRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    
    [self.threadsTableView endUpdates];
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
    
    UITableViewCell *cell = [self.threadsTableView dequeueReusableCellWithIdentifier:TableViewCellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = [thread uniqueId];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    __block KThread *thread = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        thread = [[transaction extension:@"KThreadDatabaseViewExtension"] objectAtIndexPath:indexPath withMappings:self.threadMappings];
    }];
    //if(thread) [self goToThread:thread];
}


@end
