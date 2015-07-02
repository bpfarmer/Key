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

@interface EditPostViewController ()

@property (nonatomic) IBOutlet UITextView *postText;

@end

@implementation EditPostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.postText.layer.borderWidth = 1.0f;
    self.postText.layer.borderColor = [[UIColor grayColor] CGColor];
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
    [self presentViewController:selectRecipientView animated:NO completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
