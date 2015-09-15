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
#import "ThreadViewController.h"
#import "KThread.h"
#import "KAttachable.h"
#import "CheckDevicesRequest.h"
#import "CollapsingFutures.h"
#import "KObjectRecipient.h"

@interface SelectRecipientViewController ()

@property (nonatomic) IBOutlet UITableView *contactsTableView;
@property (nonatomic) NSArray *selectedRecipients;
@property (nonatomic, strong) IBOutlet UIButton *persistenceButton;

@end

@implementation SelectRecipientViewController

- (void)viewDidLoad {
    self.currentUser = [KAccountManager sharedManager].user;
    self.tableView = self.contactsTableView;
    self.sectionCriteria = @[@{@"class" : @"KUser", @"criteria" : @{}}];
    self.sortedByProperty = @"username";
    self.sortDescending   = NO;
    [super viewDidLoad];
    self.ephemeral = NO;
    self.selectedRecipients = @[self.currentUser];
}

- (NSArray *)modifySectionData:(NSArray *)sectionData {
    NSMutableArray *newData = [NSMutableArray arrayWithArray:sectionData];
    NSMutableArray *newSectionData = [NSMutableArray arrayWithArray:sectionData[0]];
    for(KUser *user in sectionData[0]) if([user.uniqueId isEqualToString:self.currentUser.uniqueId]) [newSectionData removeObject:user];
    if(!self.sendingDelegate) [newSectionData insertObject:@"Everyone" atIndex:0];
    [newData replaceObjectAtIndex:0 withObject:newSectionData];
    return [newData copy];
}


- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSObject *object = [self objectForIndexPath:indexPath];
    UITableViewCell *cell = [self.contactsTableView dequeueReusableCellWithIdentifier:[self cellIdentifier] forIndexPath:indexPath];
    if([object isKindOfClass:[NSString class]]) {
        cell.textLabel.text = (NSString *)object;
    }else {
        KUser *user = (KUser *)[self objectForIndexPath:indexPath];
        cell.textLabel.text = [user displayName];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    NSObject *object = [self objectForIndexPath:indexPath];
    if([object isKindOfClass:[NSString class]]) {
        for(int i = 0; i < ((NSArray *)self.sectionData[indexPath.section]).count; i++) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section] animated:NO scrollPosition:UITableViewScrollPositionNone];
            [self addObjectToSelectedRecipients:[self objectForIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section]]];
        }
    }else [self addObjectToSelectedRecipients:object];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSObject *object = [self objectForIndexPath:indexPath];
    if([object isKindOfClass:[NSString class]]) {
        for(int i = 0; i < ((NSArray *)self.sectionData[indexPath.section]).count; i++) {
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section] animated:NO];
            self.selectedRecipients = @[];
        }
    }else {
        KUser *user = (KUser *)[self objectForIndexPath:indexPath];
        NSMutableArray *selected = [[NSMutableArray alloc] initWithArray:self.selectedRecipients];
        [selected removeObject:user];
        [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:NO];
        self.selectedRecipients = selected;
    }
}

- (void)addObjectToSelectedRecipients:(NSObject *)object {
    if([object isKindOfClass:[KUser class]]) {
        NSMutableArray *selected = [[NSMutableArray alloc] initWithArray:self.selectedRecipients];
        if(![selected containsObject:object]) {
            [selected addObject:object];
            self.selectedRecipients = [selected copy];
        }
    }
}

- (IBAction)sendToRecipients:(id)sender {
    dispatch_async([self.class sharedQueue], ^{
        if(self.selectedRecipients.count > 1) {
            NSMutableArray *selectedRecipientIds = [NSMutableArray new];
            for(KDatabaseObject *recipient in self.selectedRecipients) [selectedRecipientIds addObject:recipient.uniqueId];
            if(![self.sendableObject isKindOfClass:[KThread class]]) [self setThreadIdWithRecipientIds:selectedRecipientIds];
            [self.sendableObject sendToRecipientIds:selectedRecipientIds withAttachableObjects:self.attachableObjects];
            if(self.sendingDelegate) [self.sendingDelegate setSendableObject:self.sendableObject];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate dismissAndPresentViewController:nil];
            });
        }
    });
}

- (void)setThreadIdWithRecipientIds:(NSArray *)recipientIds {
    if(recipientIds.count > 1) {
        KThread *thread = [KThread findById:[KThread uniqueIdFromUserIds:recipientIds]];
        if(thread) self.sendableObject.threadId = thread.uniqueId;
    }
}

- (IBAction)didPressEphemeral:(id)sender {
    if(!self.ephemeral) {
        self.ephemeral = YES;
        [self.persistenceButton setTitle:@"Persistent: NO" forState:UIControlStateNormal];
    }else {
        self.ephemeral = NO;
        [self.persistenceButton setTitle:@"Persistent: YES" forState:UIControlStateNormal];
    }
}

- (IBAction)didPressCancel:(id)sender {
    if(self.sendingDelegate) {
        [self.sendingDelegate didCancel];
    }
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

@end
