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

// TODO: show 'waiting' spinner animation
- (IBAction)createNewUser:(id)sender {
    if(![self.usernameText.text isEqualToString:@""]) {
        TOCFuture *futureUser = [KUser asyncCreateWithUsername:self.usernameText.text password:self.passwordText.text];
        
        [futureUser catchDo:^(id error) {
            NSLog(@"There was an error (%@) creating the user.", error);
        }];
        [futureUser thenDo:^(KUser *user) {
            [[KAccountManager sharedManager] setUser:user];
            [[KStorageManager sharedManager] setDatabaseWithName:user.username];
            [user save];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                KDevice *device = [[KDevice alloc] initWithUserId:user.uniqueId deviceId:[[UIDevice currentDevice].identifierForVendor UUIDString] isCurrentDevice:YES];
                [device save];
                NSLog(@"CURRENT DEVICE :%@", user.currentDevice.deviceId);
                [user setupIdentityKey];
                [user asyncUpdate];
                [user asyncSetupPreKeys];
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

@end
