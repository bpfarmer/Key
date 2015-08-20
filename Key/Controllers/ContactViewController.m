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
#import "KPost.h"
#import "ProfileViewController.h"

static NSString *TableViewCellIdentifier = @"Contacts";

@interface ContactViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) IBOutlet UITableView *contactsTableView;
@property (nonatomic, strong) IBOutlet UITextField *contactTextField;
@property (nonatomic) KUser *currentUser;
@property (nonatomic) NSArray *contacts;
@end

@implementation ContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentUser = [KAccountManager sharedManager].user;
    self.contacts    = [KUser all];
    self.contactsTableView.dataSource = self;
    self.contactsTableView.delegate = self;
    [self.contactsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewCellIdentifier];
    self.contactsTableView.scrollEnabled = YES;
    self.contactTextField.delegate = self;
    
    UITapGestureRecognizer *tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)];
    [tapRec setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:tapRec];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseModified:) name:[KUser notificationChannel] object:nil];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [textField becomeFirstResponder];
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
    KUser *user = (KUser *)self.contacts[indexPath.row];
    cell.textLabel.text = user.displayName;
    KPost *post = [KPost findByDictionary:@{@"authorId" : user.uniqueId, @"ephemeral" : @NO}];
    UIImage *preview;
    if(post) {
        preview = [KPost imageWithImage:[UIImage imageWithData:post.previewImage] scaledToFillSize:CGSizeMake(40, 40)];
    }else {
        CGSize size = CGSizeMake(40, 40);
        UIGraphicsBeginImageContextWithOptions(size, YES, 0);
        [[UIColor whiteColor] setFill];
        UIRectFill(CGRectMake(0, 0, size.width, size.height));
        preview = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    cell.imageView.image = preview;
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    KUser *user = (KUser *)self.contacts[indexPath.row];
    if(user) {
        [self presentProfileViewControllerForUser:user];
    }
}

- (void)presentProfileViewControllerForUser:(KUser *)user {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithNibName:@"ProfileView" bundle:nil];
        profileViewController.user = user;
        [self addChildViewController:profileViewController];
        profileViewController.view.frame = self.view.frame;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view addSubview:profileViewController.view];
        });
        [profileViewController didMoveToParentViewController:self];
    });
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
        }
        self.contactTextField.text = @"";
    }
}

- (void)dismissProfileViewController:(UIViewController *)controller {
    [controller willMoveToParentViewController:nil];
    [controller.view removeFromSuperview];
    [controller removeFromParentViewController];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)resignFirstResponder {
    return YES;
}

@end
