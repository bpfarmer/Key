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
#import "KMessage.h"
#import "FreeKey.h"
#import "FreeKeyNetworkManager.h"
#import "JSQMessagesAvatarImageFactory.h"

static NSString *TableViewCellIdentifier = @"Messages";

@interface ThreadViewController () <UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) UITextField *recipientTextField;
@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) KUser *currentUser;
@end

@implementation ThreadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentUser = [KAccountManager sharedManager].user;
    self.senderDisplayName = self.currentUser.username;
    self.senderId = self.currentUser.uniqueId;
    
    if(self.thread) {
    }else {
        self.recipientTextField =
        [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.navigationController.navigationBar.frame.size.width - 50.0, 30.0)];
        self.recipientTextField.tag = 1;
        self.recipientTextField.center = self.navigationItem.titleView.center;
        self.recipientTextField.borderStyle = UITextBorderStyleRoundedRect;
        self.recipientTextField.delegate = self;
        self.titleView = self.navigationItem.titleView;
        self.navigationItem.titleView = self.recipientTextField;
    }
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    self.incomingBubbleImageData =
    [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    self.outgoingBubbleImageData =
    [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleBlueColor]];
    
    self.showLoadEarlierMessagesHeader = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    if(self.thread) {
        self.title = self.thread.displayName;
        [self.thread setRead:YES];
        [self.thread save];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 0;//[self.messageMappings numberOfItemsInSection:section];
}

- (id <JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self messageAtIndexPath:indexPath];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    id <JSQMessageData> message = [self messageAtIndexPath:indexPath];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImageData;
    }
    
    return self.incomingBubbleImageData;
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    id <JSQMessageData> msg = [self messageAtIndexPath:indexPath];
    
    if ([msg.senderId isEqualToString:self.senderId]) {
        cell.textView.textColor = [UIColor whiteColor];
    }
    
    return cell;
}


- (id<JSQMessageData>)messageAtIndexPath:(NSIndexPath *)indexPath {
    return nil;//message;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    KMessage *message = (KMessage *)[self messageAtIndexPath:indexPath];
    NSString *userInitial = [[message.senderDisplayName substringToIndex:1] uppercaseString];
    if (![message.senderId isEqualToString:self.senderId]) {
        return [JSQMessagesAvatarImageFactory avatarImageWithUserInitials:userInitial backgroundColor:[UIColor jsq_messageBubbleLightGrayColor] textColor:[UIColor whiteColor] font:[UIFont boldSystemFontOfSize:14.0]diameter:28];
    }else {
        return nil;
    }
}

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date {
    if (text.length > 0) {
        [JSQSystemSoundPlayer jsq_playMessageSentSound];
        
        if (!self.thread) {
            [self setupThread];
        }
        
        if(self.thread) {
            KMessage *message = [[KMessage alloc] initWithAuthorId:self.senderId threadId:self.thread.uniqueId body:text];
            [message save];
            
            dispatch_queue_t queue = dispatch_queue_create([kEncryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
            dispatch_async(queue, ^{
                [FreeKey sendEncryptableObject:message recipients:self.thread.recipientIds];
            });
            
            self.inputToolbar.contentView.textView.text = @"";
            [self scrollToBottomAnimated:YES];
        }
    }
}

- (void)setupThread {
    NSArray *usernames = [self.recipientTextField.text componentsSeparatedByString:@", "];
    NSMutableArray *users = [[NSMutableArray alloc] init];
    [usernames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        KUser *user = [KUser fetchObjectWithUsername:obj];
        if(user) {
            [users addObject:user];
        }
    }];
    if([users count] != [usernames count]) return;
    [users addObject:[[KAccountManager sharedManager] user]];
    self.thread = [[KThread alloc] initWithUsers:users];
    [self.thread save];
    KUser *currentUser = [[KAccountManager sharedManager] user];
    [users enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        KUser *user = (KUser *)obj;
        if(![user.uniqueId isEqual:currentUser.uniqueId]) {
            [FreeKey sendEncryptableObject:self.thread recipients:self.thread.recipientIds];
        }
    }];
    [self.recipientTextField setHidden:YES];
    self.navigationItem.titleView = self.titleView;
    self.navigationItem.title = self.thread.displayName;
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Media messages" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Send photo", @"Send location", @"Send video", nil];
    
    [sheet showFromToolbar:self.inputToolbar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    switch (buttonIndex) {
        case 0:
            //[self.demoData addPhotoMediaMessage];
            break;
            
        case 1:
        {
            __weak UICollectionView *weakView = self.collectionView;
            
            /*[self.demoData addLocationMediaMessageCompletion:^{
                [weakView reloadData];
            }];*/
        }
            break;
            
        case 2:
            //[self.demoData addVideoMediaMessage];
            break;
    }
    
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    [self finishSendingMessageAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [aTextField resignFirstResponder];
    return YES;
}

@end
