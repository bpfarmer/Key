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
#import "KMessage.h"
#import "CollapsingFutures.h"

static NSString *TableViewCellIdentifier = @"Contacts";

@interface ContactViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (nonatomic, strong) IBOutlet UITableView *contactsTableView;
@property (nonatomic, strong) IBOutlet UITextField *contactTextField;
@property (nonatomic) KUser *currentUser;
@property (nonatomic) NSArray *contacts;
@end

@implementation ContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentUser = [KAccountManager sharedManager].user;
    self.contacts    = self.currentUser.contacts;
    self.contactsTableView.dataSource = self;
    self.contactsTableView.delegate = self;
    [self.contactsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewCellIdentifier];
    self.contactTextField.delegate = self;
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(databaseModified:)
                                                 name:[KUser notificationChannel]
                                               object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)databaseModified:(NSNotification *)notification {
    if([[notification object] isKindOfClass:[KUser class]]) {
        for(KUser *contact in self.contacts) if([contact.uniqueId isEqualToString:((KUser *)notification.object).uniqueId] || [((KUser *)notification.object).uniqueId isEqualToString:self.currentUser.uniqueId]) return;
        NSMutableArray *contacts = [[NSMutableArray alloc] initWithArray:self.contacts];
        [contacts addObject:[notification object]];
        self.contacts = [[NSArray alloc] initWithArray:contacts];
        [self.contactsTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(self.contacts.count - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender {
    return 1;
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section {
    return self.contacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.contactsTableView dequeueReusableCellWithIdentifier:TableViewCellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = ((KUser *)self.contacts[indexPath.row]).displayName;
    return cell;
}

- (IBAction)addContact:(id)sender {
    if(![self.contactTextField.text isEqualToString:@""] &&
       ![self.contactTextField.text isEqualToString:self.currentUser.username]) {
        KUser *targetUser = [KUser findByDictionary:@{@"username" : [self.contactTextField.text lowercaseString]}];
        if(!targetUser) {
            TOCFuture *futureUser = [KUser asyncRetrieveWithUsername:[self.contactTextField.text lowercaseString]];
            
            [futureUser catchDo:^(id failure) {
                NSLog(@"ERROR: %@", failure);
            }];
            
            [futureUser thenDo:^(KUser *user) {
                [[KAccountManager sharedManager].user asyncRetrieveKeyExchangeWithRemoteUser:user];
            }];
        }
        self.contactTextField.text = @"";
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)resignFirstResponder {
    return YES;
}

@end
