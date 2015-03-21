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
#import "HomeViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.usernameText.delegate = self;
    self.passwordText.delegate = self;
    
    // Do any additional setup after loading the view.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)login:(id)sender {
    KUser *user = [[KUser alloc] initWithUsername:[self.usernameText.text lowercaseString]];
    [[KAccountManager sharedManager] setUser:user];
    if([user authenticatePassword:self.passwordText.text]) {
        [[KStorageManager sharedManager] refreshDatabaseAndConnection];
        [[KStorageManager sharedManager] setupDatabase];
        KUser *retrievedUser = [KUser fetchObjectWithUsername:user.username];
        if(retrievedUser) {
            [[KAccountManager sharedManager] setUser:retrievedUser];
            [self showHome];
        }else {
            NSLog(@"PROBLEM RETRIEVING USER FROM DB");
        }
    }else {
      NSLog(@"ERROR LOGGING IN");
    }
}

- (void)showHome {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    HomeViewController *inboxView = [storyboard instantiateViewControllerWithIdentifier:@"HomeViewController"];
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
