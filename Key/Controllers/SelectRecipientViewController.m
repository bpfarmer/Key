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
#import "ThreadViewController.h"
#import "KThread.h"

static NSString *TableViewCellIdentifier = @"Recipients";

@interface SelectRecipientViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) IBOutlet UITableView *contactsTableView;
@property (nonatomic) NSArray *selectedRecipients;
@property (nonatomic) NSArray *contacts;

@end

@implementation SelectRecipientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"HERE");
    
    self.contacts = [[KAccountManager sharedManager].user contacts];
    
    self.contactsTableView.dataSource = self;
    self.contactsTableView.delegate = self;
    [self.contactsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewCellIdentifier];
    
    if(![self.desiredObject isEqualToString:kSelectRecipientsForMessage]) {
        if(!self.post) {
            self.post = [[KPost alloc] initWithAuthorId:[KAccountManager sharedManager].uniqueId text:nil];
        }
        self.post.attachments = self.sendableObjects;
    }
    
    self.contactsTableView.allowsMultipleSelection = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender {
    return 1;
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section {
    return self.contacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    KUser *user = self.contacts[indexPath.row];
    UITableViewCell *cell = [self.contactsTableView dequeueReusableCellWithIdentifier:TableViewCellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = [user displayName];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    KUser *user = self.contacts[indexPath.row];
    NSMutableArray *selected = [[NSMutableArray alloc] initWithArray:self.selectedRecipients];
    [selected addObject:user];
    self.selectedRecipients = selected;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    KUser *user = self.contacts[indexPath.row];
    NSMutableArray *selected = [[NSMutableArray alloc] initWithArray:self.selectedRecipients];
    [selected removeObject:user];
    self.selectedRecipients = selected;
}

- (IBAction)sendToRecipients:(id)sender {
    if(self.selectedRecipients.count > 0) {
        if([self.desiredObject isEqualToString:kSelectRecipientsForMessage]) {
            KThread *thread = [self setupThread];
            ThreadViewController *threadViewController = [[ThreadViewController alloc] initWithNibName:@"ThreadView" bundle:nil];
            threadViewController.thread = thread;
            [self.delegate dismissAndPresentThread:thread];
        }else {
            [self.post save];
            NSMutableArray *recipientIds = [[NSMutableArray alloc] init];
            for(KUser *user in self.selectedRecipients) [recipientIds addObject:user.uniqueId];
            [FreeKey sendEncryptableObject:self.post recipients:recipientIds];
            [self dismissViewControllerAnimated:NO completion:nil];
        }
    }else {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (IBAction)didPressCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (KThread *)setupThread {
    if(self.selectedRecipients.count == 0) return nil;
    NSMutableArray *users = [[NSMutableArray alloc] initWithArray:self.selectedRecipients];
    [users addObject:[KAccountManager sharedManager].user];
    KThread *thread = [[KThread alloc] initWithUsers:users];
    return thread;
}


-(BOOL)prefersStatusBarHidden {
    return YES;
}

@end
