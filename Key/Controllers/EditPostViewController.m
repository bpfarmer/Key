//
//  EditPostViewController.m
//  Key
//
//  Created by Brendan Farmer on 6/30/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "EditPostViewController.h"
#import "SelectRecipientViewController.h"
#import "KPost.h"
#import "KAccountManager.h"
#import "KLocation.h"

@interface EditPostViewController ()

@property (nonatomic) IBOutlet UITextView *postText;
@property (nonatomic) IBOutlet UIButton *locationButton;
@property (nonatomic) BOOL locationEnabled;
@property (nonatomic) BOOL toDismiss;

@end

@implementation EditPostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.postText.layer.borderWidth = 1.0f;
    self.postText.layer.borderColor = [[UIColor grayColor] CGColor];
    self.locationEnabled = YES;
    [[KAccountManager sharedManager] refreshCurrentCoordinate];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didPressCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (IBAction)didPressPost:(id)sender {
    KPost *post = [[KPost alloc] initWithAuthorId:[KAccountManager sharedManager].uniqueId text:self.postText.text];
    SelectRecipientViewController *selectRecipientView = [[SelectRecipientViewController alloc] initWithNibName:@"SelectRecipientsView" bundle:nil];
    selectRecipientView.post = post;
    NSMutableArray *sendableObjects = [[NSMutableArray alloc] init];
    if(self.locationEnabled) {
        [sendableObjects addObject:[[KLocation alloc] initWithUserUniqueId:[KAccountManager sharedManager].uniqueId location:[KAccountManager sharedManager].currentCoordinate]];
    }
    [selectRecipientView setSendableObjects:sendableObjects];
    [self.delegate dismissAndPresentViewController:selectRecipientView];
}

- (IBAction)didPressLocation:(id)sender {
    if(!self.locationEnabled) {
        self.locationEnabled = YES;
        [self.locationButton setTitle:@"Location On" forState:UIControlStateNormal];
    }else {
        self.locationEnabled = NO;
        [self.locationButton setTitle:@"Location Off" forState:UIControlStateNormal];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    
}

@end
