//
//  loginViewController.m
//  Key
//
//  Created by Brendan on 1/27/15.
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
        [futureSalt catchDo:^(id failure) {
            NSLog(@"PROBLEM RETRIEVING SALT");
        }];
        [futureSalt thenDo:^(NSData *passwordSalt) {
            NSData *passwordCrypt = [KUser encryptPassword:self.passwordText.text salt:passwordSalt];
            TOCFuture *futureLogin = [LoginRequest makeRequestWithParameters:@{@"username" : user.username, @"password_crypt" : passwordCrypt}];
            [futureLogin catchDo:^(id failure) {
                NSLog(@"REMOTE LOGIN ERROR");
            }];
            [futureLogin thenDo:^(KUser *remoteUser) {
                [[KStorageManager sharedManager] setDatabaseWithName:user.username];
                KUser *retrievedUser = [KUser findById:remoteUser.uniqueId];
                if(!retrievedUser) {
                    [remoteUser save];
                    [remoteUser setupKeysForDevice];
                }
                [[KAccountManager sharedManager] setUser:[KUser findById:remoteUser.uniqueId]];
                [self showHome];
            }];
        }];
    }else {
        NSLog(@"Username and Password cannot be blank");
    }
}

- (IBAction)createNewUser:(id)sender {
    if(![self.usernameText.text isEqualToString:@""]) {
        TOCFuture *futureUser = [KUser asyncCreateWithUsername:self.usernameText.text password:self.passwordText.text];
        
        [futureUser catchDo:^(id error) {
            NSLog(@"There was an error (%@) creating the user.", error);
        }];
        [futureUser thenDo:^(KUser *user) {
            [[KStorageManager sharedManager] setDatabaseWithName:user.username];
            [user save];
            [[KAccountManager sharedManager] setUser:user];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [user setupKeysForDevice];
                NSLog(@"CURRENT DEVICE :%@", user.currentDeviceId);
            });
            [self showHome];
        }];
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

@end
