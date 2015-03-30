//
//  registrationViewController.m
//  Key
//
//  Created by Loren on 1/27/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "RegistrationViewController.h"
#import "KUser.h"
#import "KAccountManager.h"
#import "KStorageManager.h"
#import "HttpManager.h"
#import "CollapsingFutures.h"

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
}

- (IBAction)createNewUser:(id)sender {
    if(![self.usernameText.text isEqualToString:@""]) {
        // TODO: show 'waiting' spinner animation
        TOCFuture *futureUser = [KUser asyncCreateWithUsername:self.usernameText.text password:self.passwordText.text];
        
        [futureUser catchDo:^(id error) {
            NSLog(@"There was an error (%@) creating the user.", error);
        }];
        [futureUser thenDo:^(KUser *user) {
            [[KAccountManager sharedManager] setUser:user];
            [[KStorageManager sharedManager] refreshDatabaseAndConnection];
            [[KStorageManager sharedManager] setupDatabase];
            [user save];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [user setupIdentityKey];
                [user save];
                [user asyncUpdate];
                [user asyncSetupPreKeys];
            });
            [self showInbox];
        }];
    }
}

- (void)showInbox {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UIViewController *inboxView = [storyboard instantiateViewControllerWithIdentifier:@"HomeViewController"];
    [self presentViewController:inboxView animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
