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
#import "KUser.h"
#import "KPost.h"
#import "KPhoto.h"
#import "KLocation.h"
#import "FreeKey.h"
#import "FreeKeyNetworkManager.h"

static NSString *TableViewCellIdentifier = @"Recipients";

@interface SelectRecipientViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *contactsTableView;
@property (nonatomic) NSArray *selectedRecipients;

@end

@implementation SelectRecipientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.contactsTableView.dataSource = self;
    self.contactsTableView.delegate = self;
    [self.contactsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewCellIdentifier];
    
    if(!self.post) {
        self.post = [[KPost alloc] initWithAuthorId:[KAccountManager sharedManager].uniqueId text:nil];
    }
    
    self.contactsTableView.allowsMultipleSelection = YES;
    
    self.post.attachments = self.sendableObjects;
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

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    __block KUser *user = nil;
}

- (IBAction)sendToRecipients:(id)sender {
    [FreeKey sendEncryptableObject:self.post recipients:self.selectedRecipients];
    [self.post save];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)didPressCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(BOOL)prefersStatusBarHidden {
    return YES;
}

@end
