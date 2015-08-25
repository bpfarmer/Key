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

@interface ContactViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) IBOutlet UITableView *contactsTableView;
@property (nonatomic, strong) IBOutlet UITextField *contactTextField;
@property (nonatomic) KUser *currentUser;
@end

@implementation ContactViewController

- (void)viewDidLoad {
    self.currentUser = [KAccountManager sharedManager].user;
    self.tableView = self.contactsTableView;
    self.sectionCriteria = @[@{@"class" : @"KUser",
                               @"criteria" : @{}}];
    self.sortedByProperty = @"username";
    self.sortDescending   = NO;
    [super viewDidLoad];
    self.contactTextField.delegate = self;
    
    NSMutableArray *data = [NSMutableArray arrayWithArray:self.sectionData];
    NSMutableArray *sectionData = [NSMutableArray arrayWithArray:self.sectionData[0]];
    for(KUser *user in sectionData) if([user.uniqueId isEqualToString:self.currentUser.uniqueId]) [sectionData removeObject:user];
    [sectionData insertObject:self.currentUser atIndex:0];
    [data replaceObjectAtIndex:0 withObject:sectionData];
    self.sectionData = data;
    
    UITapGestureRecognizer *tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)];
    [tapRec setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:tapRec];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [textField becomeFirstResponder];
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.contactsTableView dequeueReusableCellWithIdentifier:[self cellIdentifier] forIndexPath:indexPath];
    KUser *user = (KUser *)[self objectForIndexPath:indexPath];
    if([user.uniqueId isEqualToString:self.currentUser.uniqueId]) cell.textLabel.text = @"Me";
    else cell.textLabel.text = user.displayName;
    KPost *post = [KPost findByDictionary:@{@"authorId" : user.uniqueId, @"ephemeral" : @NO, @"attachmentCount" : [NSNumber numberWithInteger:0]}];
    UIImage *preview;
    if(post) {
        preview = [KPost imageWithImage:[UIImage imageWithData:post.previewImage] scaledToFillSize:CGSizeMake(40, 40)];
    }else {
        preview = [self whiteImage];
    }
    cell.imageView.image = preview;
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}

- (UIImage *)whiteImage {
    UIImage *image;
    CGSize size = CGSizeMake(40, 40);
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    [[UIColor whiteColor] setFill];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    KUser *user = (KUser *)[self objectForIndexPath:indexPath];
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
    if(![self.contactTextField.text isEqualToString:@""] && ![self.contactTextField.text isEqualToString:self.currentUser.username]) {
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

@end
