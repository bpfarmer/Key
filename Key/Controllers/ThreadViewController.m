//
//  ThreadViewController.m
//  Key
//
//  Created by Brendan Farmer on 3/18/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ThreadViewController.h"
#import "KUser.h"
#import "KAccountManager.h"
#import "KThread.h"
#import "KStorageManager.h"
#import "KYapDatabaseView.h"
#import "KMessage.h"
#import "FreeKey.h"
#import "FreeKeyNetworkManager.h"

static NSString *TableViewCellIdentifier = @"Messages";

YapDatabaseViewMappings *mappings;
YapDatabaseConnection *databaseConnection;

@interface ThreadViewController () <UITableViewDataSource>
@property (nonatomic, strong) IBOutlet UITableView *messagesTableView;
@property (nonatomic, strong) IBOutlet UITextField *messageTextField;
@property (nonatomic, strong) IBOutlet UITextField *recipientTextField;
@property (nonatomic, strong) IBOutlet UIView *headerView;
@property (nonatomic, strong) KUser *curentUser;
@property (nonatomic, strong) YapDatabaseConnection   *databaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *messageMappings;
@end

@implementation ThreadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.messagesTableView.dataSource = self;
    [self.messagesTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewCellIdentifier];
    
    if(self.thread) {
        [self setupDatabaseView];
    }
}

- (void) setupDatabaseView {
    _databaseConnection = [[KStorageManager sharedManager] newDatabaseConnection];
    [self.databaseConnection beginLongLivedReadTransaction];
    _messageMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[self.thread.uniqueId]
                                                                  view:@"KMessageDatabaseViewExtension"];

    
    [self.databaseConnection beginLongLivedReadTransaction];
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
        [self.messageMappings updateWithTransaction:transaction];
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
    
    [[self.databaseConnection ext:@"KMessageDatabaseViewExtension"] getSectionChanges:&sectionChanges
                                                                               rowChanges:&rowChanges
                                                                         forNotifications:notifications
                                                                             withMappings:self.messageMappings];
    
    if ([sectionChanges count] == 0 & [rowChanges count] == 0)
    {
        return;
    }
    
    [self.messagesTableView beginUpdates];
    
    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges)
    {
        switch (sectionChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.messagesTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.messagesTableView insertSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
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
                [self.messagesTableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.messagesTableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                    withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove :
            {
                [self.messagesTableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.messagesTableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate :
            {
                [self.messagesTableView reloadRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    
    [self.messagesTableView endUpdates];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    if ([self.messageMappings numberOfItemsInAllGroups] == 0) return 1;
    else return [self.messageMappings numberOfSections];
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section
{
    return [self.messageMappings numberOfItemsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block KMessage *message;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        message = (KMessage *)[[transaction extension:@"KMessageDatabaseViewExtension"] objectAtIndexPath:indexPath withMappings:self.messageMappings];
    }];
    
    UITableViewCell *cell = [self.messagesTableView dequeueReusableCellWithIdentifier:TableViewCellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = message.body;
    return cell;
}

- (IBAction)createMessage:(id)sender {
    if (!self.thread) {
        [self setupThread];
    }
    
    [self.messagesTableView reloadData];
    
    KMessage *message = [[KMessage alloc] initWithAuthorId:[KAccountManager sharedManager].uniqueId
                                                  threadId:self.thread.uniqueId
                                                      body:self.messageTextField.text];
    [message save];
    KUser *currentUser = [[KAccountManager sharedManager] user];
    
    [self.thread.userIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if(![obj isEqual:currentUser.uniqueId]) {
            dispatch_queue_t queue = dispatch_queue_create([kEncryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
            dispatch_async(queue, ^{
                KUser *user = (KUser *)[[KStorageManager sharedManager] objectForKey:obj inCollection:[KUser collection]];
                if(user) {
                    [[FreeKeyNetworkManager sharedManager] enqueueEncryptableObject:message localUser:currentUser remoteUser:user];
                }
            });
        }
    }];
    self.messageTextField.text = @"";
}

- (void)setupThread {
    NSArray *usernames = [self.recipientTextField.text componentsSeparatedByString:@", "];
    NSMutableArray *users = [[NSMutableArray alloc] init];
    [usernames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        KUser *user = [KUser fetchObjectWithUsername:obj];
        if(user) [users addObject:user];
    }];
    [users addObject:[[KAccountManager sharedManager] user]];
    self.thread = [[KThread alloc] initWithUsers:users];
    [self.thread save];
    KUser *currentUser = [[KAccountManager sharedManager] user];
    [users enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        KUser *user = (KUser *)obj;
        if(![user.uniqueId isEqual:currentUser.uniqueId]) {
            [[FreeKeyNetworkManager sharedManager] enqueueEncryptableObject:self.thread localUser:currentUser remoteUser:user];
        }
    }];
    [self setupDatabaseView];
}

@end
