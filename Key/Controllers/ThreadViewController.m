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
#import "JSQMessagesAvatarImageFactory.h"
#import "CheckDevicesRequest.h"
#import "CollapsingFutures.h"
#import "ShareViewController.h"
#import "DismissAndPresentProtocol.h"
#import "KPost.h"
#import "MediaViewController.h"
#import "ObjectRecipient.h"

static NSString *TableViewCellIdentifier = @"Messages";

@interface ThreadViewController () <UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate, DismissAndPresentProtocol>
@property (nonatomic, strong) UITextField *recipientTextField;
@property (nonatomic) UIView *titleView;
@property (nonatomic) NSArray *messages;
@property (nonatomic) NSArray *posts;
@property (nonatomic, strong) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, weak)   UIView *navView;
@end

@interface UINavigationItem(){
    UIView *backButtonView;
}
@end

@implementation ThreadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    KUser *currentUser = [KAccountManager sharedManager].user;
    self.senderDisplayName = currentUser.username;
    self.senderId = currentUser.uniqueId;
    
    self.messages = @[];
    
    if(self.thread && self.thread.saved) {
        NSMutableArray *messages = [NSMutableArray arrayWithArray:self.thread.messages];
        [messages addObjectsFromArray:self.thread.posts];
        [messages sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[obj1 createdAt] compare:[obj2 createdAt]];
        }];
        self.messages = [messages copy];
    }
    
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleBlueColor]];
    
    self.showLoadEarlierMessagesHeader = NO;
    
    self.titleView = self.navigationItem.titleView;
    self.navigationItem.titleView = self.recipientTextField;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    //[self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseModified:) name:[KMessage notificationChannel] object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseModified:) name:[KPost notificationChannel] object:nil];
}

- (void)databaseModified:(NSNotification *)notification {
    if([notification.object isKindOfClass:[KMessage class]]) {
        if(![((KMessage *)notification.object).threadId isEqualToString:self.thread.uniqueId]) return;
        NSMutableArray *messages = [[NSMutableArray alloc] initWithArray:self.messages];
        [messages addObject:[notification object]];
        self.messages = [messages copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:(self.messages.count - 1) inSection:0]]];
            [self scrollToBottomAnimated:YES];
        });
    }else if([notification.object isKindOfClass:[KPost class]]) {
        KPost *post = (KPost *)notification.object;
        if(post.attachmentCount == 0) return;
        if(![post.threadId isEqualToString:self.thread.uniqueId]) {
            if(![ObjectRecipient findByDictionary:@{@"objectId" : post.uniqueId, @"type" : NSStringFromClass(post.class), @"recipientId" : self.thread.recipientIds.firstObject}]) return;
        }
        for(KDatabaseObject *object in self.messages) if([object.uniqueId isEqualToString:post.uniqueId]) return;
        NSMutableArray *posts = [[NSMutableArray alloc] initWithArray:self.messages];
        [posts addObject:post];
        self.messages = [posts copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:(self.messages.count - 1) inSection:0]]];
            [self scrollToBottomAnimated:YES];
        });
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    if(self.thread) {
        self.title = self.thread.displayName;
        
        if(!self.thread.read) {
            [self.thread setRead:YES];
            [self.thread save];
        }
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
    return self.messages.count;
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
    
    if([self.messages[indexPath.row] isKindOfClass:[KPost class]]) {
        cell.messageBubbleImageView.image = [UIImage imageWithData:((KPost *)self.messages[indexPath.row]).previewImage];
    }

    
    return cell;
}


- (id<JSQMessageData>)messageAtIndexPath:(NSIndexPath *)indexPath {
    if([self.messages[indexPath.row] isKindOfClass:[KMessage class]])
        return self.messages[indexPath.row];
    else {
        KPost *post = self.messages[indexPath.row];
        JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:[UIImage imageWithData:post.previewImage]];
        return [JSQMessage messageWithSenderId:post.authorId displayName:post.author.username media:photoItem];
    }
}


- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row < self.messages.count) {
        KMessage *message = (KMessage *)[self messageAtIndexPath:indexPath];
        NSString *userInitial = [[message.senderDisplayName substringToIndex:1] uppercaseString];
        if (![message.senderId isEqualToString:self.senderId]) {
            return [JSQMessagesAvatarImageFactory avatarImageWithUserInitials:userInitial backgroundColor:[UIColor jsq_messageBubbleLightGrayColor] textColor:[UIColor whiteColor] font:[UIFont boldSystemFontOfSize:14.0]diameter:28];
        }
    }
    return nil;
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath {
    [super collectionView:collectionView didTapMessageBubbleAtIndexPath:indexPath];
    if([self.messages[indexPath.row] isKindOfClass:[KPost class]]) {
        MediaViewController *mediaViewController = [[MediaViewController alloc] initWithNibName:@"MediaView" bundle:nil];
        mediaViewController.post = (KPost *)self.messages[indexPath.row];
        [self presentViewController:mediaViewController animated:NO completion:nil];
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date {
    if (text.length > 0) {
        [JSQSystemSoundPlayer jsq_playMessageSentSound];
        
        if(self.thread.uniqueId) {
            KMessage *message = [[KMessage alloc] initWithAuthorId:[KAccountManager sharedManager].user.uniqueId threadId:self.thread.uniqueId body:text];
            [message save];
            dispatch_queue_t queue = dispatch_queue_create([kEncryptObjectQueue cStringUsingEncoding:NSASCIIStringEncoding], NULL);
            dispatch_async(queue, ^{
                TOCFuture *futureDevices = [FreeKey prepareSessionsForRecipientIds:self.thread.recipientIds];
                [futureDevices thenDo:^(id value) {
                    [FreeKey sendEncryptableObject:message recipientIds:self.thread.recipientIds];
                }];
            });
            
            self.inputToolbar.contentView.textView.text = @"";
        }
    }
}



- (void)didPressAccessoryButton:(UIButton *)sender {
    ShareViewController *shareViewController = [[ShareViewController alloc] initWithNibName:@"ShareView" bundle:nil];
    shareViewController.thread = self.thread;
    shareViewController.delegate = self;
    [self presentViewController:shareViewController animated:NO completion:nil];
}

- (void)dismissAndPresentViewController:(UIViewController *)viewController {
    [self dismissViewControllerAnimated:NO completion:^{
        if(viewController != nil) [self presentViewController:viewController animated:NO completion:nil];
        else [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (void)dismissAndPresentThread:(KThread *)thread  {
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
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

- (IBAction)didPressBack:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField {
    [aTextField resignFirstResponder];
    return YES;
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

@end
