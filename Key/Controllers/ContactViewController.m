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
#import "FreeKeyNetworkManager.h"
#import "CollapsingFutures.h"

static NSString *TableViewCellIdentifier = @"Contacts";

@interface ContactViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) IBOutlet UITableView *contactsTableView;
@property (nonatomic, strong) IBOutlet UITextField *contactTextField;
@property (nonatomic) KUser *currentUser;
@end

@implementation ContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentUser = [KAccountManager sharedManager].user;
    
    self.contactsTableView.dataSource = self;
    self.contactsTableView.delegate = self;
    [self.contactsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewCellIdentifier];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender {
    return 1;
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    __block KUser *user = nil;
}

- (IBAction)pushBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
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
                [[KAccountManager sharedManager].user asyncRetrieveKeyExchangeWithRemoteUser:user];
            }];
        }
        self.contactTextField.text = @"";
    }
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

@end
