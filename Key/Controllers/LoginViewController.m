//
//  loginViewController.m
//  Key
//
//  Created by Loren on 1/27/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "LoginViewController.h"
#import "KUser.h"
#import "KAccountManager.h"
#import "KStorageManager.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)login:(id)sender {
    KUser *user = [[KUser alloc] initWithUsername:self.usernameText.text];
    // TODO: refactor to use
    if([user authenticatePassword:self.passwordText.text]) {
        KUser *retrievedUser = [KUser fetchObjectWithUsername:user.username];
        [[KAccountManager sharedManager] setUser:retrievedUser];
        [self showInbox];
    }else {
        NSLog(@"ERROR LOGGING IN");
    }
}

- (void)showInbox {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UIViewController *inboxView = [storyboard instantiateViewControllerWithIdentifier:@"HomeViewController"];
    [self presentViewController:inboxView animated:YES completion:nil];
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
