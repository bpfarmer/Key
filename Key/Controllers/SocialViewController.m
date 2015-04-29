//
//  SocialViewController.m
//  Key
//
//  Created by Brendan Farmer on 4/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "SocialViewController.h"
#import "KStorageManager.h"
#import "KYapDatabaseView.h"
#import "KPost.h"
#import "KAccountManager.h"
#import "KUser.h"
#import "SelectRecipientViewController.h"

static NSString *TableViewCellIdentifier = @"Posts";
static NSString *KSelectRecipientSegueIdentifier = @"selectRecipientPushSegue";

@interface SocialViewController () <UITextViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITextView *postTextView;
@property (nonatomic, strong) IBOutlet UITableView *postsTableView;
@property (nonatomic, strong) YapDatabaseConnection   *databaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *postMappings;
@property (nonatomic) KUser *currentUser;
@property (nonatomic) KPost *currentPost;

@end

@implementation SocialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIColor *borderColor = [UIColor colorWithRed:204.0/255.0 green:204.0/255.0 blue:204.0/255.0 alpha:1.0];
    
    self.postTextView.layer.borderColor = borderColor.CGColor;
    self.postTextView.layer.borderWidth = 1.0;
    self.postTextView.layer.cornerRadius = 5.0;
    
    self.postTextView.delegate = self;
    
    [self.postTextView sizeToFit];
    [self.postTextView layoutIfNeeded];
    
    self.currentUser = [KAccountManager sharedManager].user;
    
    [self setupDatabaseView];
}

- (void) setupDatabaseView {
    _databaseConnection = [[KStorageManager sharedManager] newDatabaseConnection];
    [self.databaseConnection beginLongLivedReadTransaction];
    _postMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[@"KPostGroup"] view:KPostDatabaseViewName];
    
    [self.databaseConnection beginLongLivedReadTransaction];
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
        [self.postMappings updateWithTransaction:transaction];
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
    
    [[self.databaseConnection ext:KThreadDatabaseViewName] getSectionChanges:&sectionChanges
                                                                  rowChanges:&rowChanges
                                                            forNotifications:notifications
                                                                withMappings:self.postMappings];
    
    if ([sectionChanges count] == 0 & [rowChanges count] == 0)
    {
        return;
    }
    
    [self.postsTableView beginUpdates];
    
    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges)
    {
        switch (sectionChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.postsTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                                     withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.postsTableView insertSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                                     withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove :
            {
                break;
            }
            case YapDatabaseViewChangeUpdate :
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
                [self.postsTableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                             withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.postsTableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                             withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove :
            {
                [self.postsTableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                             withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.postsTableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                             withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate :
            {
                [self.postsTableView reloadRowsAtIndexPaths:@[ rowChange.indexPath ]
                                             withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    
    [self.postsTableView endUpdates];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    return [self.postMappings numberOfSections];
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section
{
    return [self.postMappings numberOfItemsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block KPost *post = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        post = (KPost *)[[transaction extension:KThreadDatabaseViewName] objectAtIndexPath:indexPath
                                                                                  withMappings:self.postMappings];
    }];
    
    UITableViewCell *cell = [self.postsTableView dequeueReusableCellWithIdentifier:TableViewCellIdentifier
                                                                        forIndexPath:indexPath];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", post.author, post.text];
    return cell;
}

- (IBAction)createNewPost:(id)sender {
    if(![self.postTextView.text isEqualToString:@""]) {
        self.currentPost = [[KPost alloc] initWithAuthorId:self.currentUser.uniqueId text:self.postTextView.text];
        [self.parentViewController performSegueWithIdentifier:KSelectRecipientSegueIdentifier sender:self];
    }else {
        NSLog(@"Post field cannot be empty");
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier] isEqual:KSelectRecipientSegueIdentifier]) {
        SelectRecipientViewController *selectRecipientController = [segue destinationViewController];
        selectRecipientController.currentUser = self.currentUser;
        selectRecipientController.post        = self.currentPost;
    }
}


@end
