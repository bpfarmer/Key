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
#import "ObjectRecipient.h"

@interface SelectRecipientViewController ()

@property (nonatomic) IBOutlet UITableView *contactsTableView;
@property (nonatomic) NSArray *selectedRecipients;
@property (nonatomic, strong) IBOutlet UIButton *persistenceButton;

@end

@implementation SelectRecipientViewController

- (void)viewDidLoad {
    self.currentUser = [KAccountManager sharedManager].user;
    self.tableView = self.contactsTableView;
    self.sectionCriteria = @[@{@"class" : @"KUser",
                               @"criteria" : @{}}];
    self.sortedByProperty = @"username";
    self.sortDescending   = NO;
    [super viewDidLoad];
    
    self.ephemeral = NO;
    
    NSMutableArray *newData = [NSMutableArray arrayWithArray:self.sectionData];
    NSMutableArray *newSectionData = [NSMutableArray arrayWithArray:self.sectionData[0]];
    for(KUser *user in newSectionData) if([user.uniqueId isEqualToString:self.currentUser.uniqueId]) [newSectionData removeObject:user];
    [newSectionData insertObject:@"Everyone" atIndex:0];
    [newData replaceObjectAtIndex:0 withObject:newSectionData];
    self.sectionData = newData;
    
    NSLog(@"EPHEMERAL SETTING: %d", self.ephemeral);
    if(![self.desiredObject isEqualToString:kSelectRecipientsForMessage]) {
        if(!self.post) {
            self.post = [[KPost alloc] initWithAuthorId:[KAccountManager sharedManager].uniqueId];
            self.post.uniqueId = [KPost generateUniqueId];
            self.post.ephemeral = self.ephemeral;
        }
    }
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
    if(self.selectedRecipients.count > 0) {
        if([self.desiredObject isEqualToString:kSelectRecipientsForMessage]) {
            KThread *thread = [self setupThread];
            ThreadViewController *threadViewController = [[ThreadViewController alloc] initWithNibName:@"ThreadView" bundle:nil];
            threadViewController.thread = thread;
            [self.delegate dismissAndPresentThread:thread];
            dispatch_queue_t queue = dispatch_queue_create([kEncryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
            dispatch_async(queue, ^{
                [thread save];
                TOCFuture *futureDevices = [FreeKey prepareSessionsForRecipientIds:thread.recipientIds];
                [futureDevices thenDo:^(id value) {
                    [FreeKey sendEncryptableObject:thread recipientIds:thread.recipientIds];
                }];
            });
        }else {
            dispatch_queue_t queue = dispatch_queue_create([kEncryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
            dispatch_async(queue, ^{
                NSMutableArray *recipientIds = [[NSMutableArray alloc] init];
                for(KUser *user in self.selectedRecipients) {
                    [recipientIds addObject:user.uniqueId];
                }
                for(KDatabaseObject <KAttachable> *object in self.sendableObjects) {
                    [object setParentId:self.post.uniqueId];
                    if([object isKindOfClass:[KPhoto class]]) [self.post incrementAttachmentCount];
                    [object save];
                    [self.post addAttachment:object];
                }
                [self.post save];
                TOCFuture *futureDevices = [FreeKey prepareSessionsForRecipientIds:recipientIds];
                [futureDevices thenDo:^(id value) {
                    [FreeKey sendEncryptableObject:self.post attachableObjects:self.sendableObjects recipientIds:recipientIds];
                }];
                
                for(NSString *recipientId in recipientIds) {
                    ObjectRecipient *or = [[ObjectRecipient alloc] initWithType:NSStringFromClass([self.post class]) objectId:self.post.uniqueId recipientId:recipientId];
                    [or save];
                }
            });
            [self.delegate dismissAndPresentViewController:nil];
        }
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
    [self dismissViewControllerAnimated:NO completion:nil];
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
