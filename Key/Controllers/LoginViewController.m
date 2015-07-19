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
#import "PushManager.h"
#import "LoginRequest.h"
#import "CollapsingFutures.h"
#import "KDevice.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.usernameText.delegate = self;
    self.passwordText.delegate = self;
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)]];
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
    if(![self.usernameText.text isEqualToString:@""] /*&& ![self.passwordText.text isEqualToString:@""]*/) {
        KUser *user = [[KUser alloc] initWithUsername:[self.usernameText.text lowercaseString]];
        TOCFuture *futureSalt = [LoginRequest makeSaltRequestWithParameters:@{@"username" : user.username}];
        [futureSalt thenDo:^(id value) {
            NSLog(@"PROBLEM RETRIEVING SALT");
        }];
        [futureSalt thenDo:^(NSData *passwordSalt) {
            NSData *passwordCrypt = [KUser encryptPassword:self.passwordText.text salt:passwordSalt];
            TOCFuture *futureLogin = [LoginRequest makeRequestWithParameters:@{@"username" : user.username, @"password_crypt" : passwordCrypt}];
            [futureLogin catchDo:^(id failure) {
                NSLog(@"REMOTE LOGIN ERROR");
            }];
            [futureLogin thenDo:^(KUser *remoteUser) {
                [[KAccountManager sharedManager] setUser:user];
                [[KStorageManager sharedManager] setDatabaseWithName:user.username];
                KUser *retrievedUser = [KUser findByDictionary:@{@"username" : user.username}];
                if(!retrievedUser) {
                    [remoteUser save];
                    KDevice *device = [[KDevice alloc] initWithUserId:remoteUser.uniqueId deviceId:[[UIDevice currentDevice].identifierForVendor UUIDString] isCurrentDevice:YES];
                    [device save];
                }
                [[KAccountManager sharedManager] setUser:remoteUser];
                [self showHome];
            }];
        }];
    }else {
        NSLog(@"Username and Password cannot be blank");
    }
}

- (void)showHome {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"MainNavigationController"];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
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
