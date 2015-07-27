//
//  registrationViewController.m
//  Key
//
//  Created by Brendan Farmer on 1/27/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "RegistrationViewController.h"
#import "KUser.h"
#import "KAccountManager.h"
#import "KStorageManager.h"
#import "HttpManager.h"
#import "CollapsingFutures.h"
#import "PushManager.h"
#import "KDevice.h"

@interface RegistrationViewController () <UITextFieldDelegate>

@end

@implementation RegistrationViewController

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.emailText.delegate = self;
    self.passwordText.delegate = self;
    self.usernameText.delegate = self;
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)]];
}

- (void)showHome {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"MainNavigationController"];
    [self presentViewController:navigationController animated:YES completion:nil];
}

@end
