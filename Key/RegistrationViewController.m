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

@interface RegistrationViewController ()

@end

@implementation RegistrationViewController

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)createNewUser:(id)sender {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveUserStatusNotification:)
                                                 name:KUserRegisterUsernameStatusNotification
                                               object:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[KUser alloc] initWithUsername:self.usernameText.text password:self.passwordText.text];
    });
}

- (void)receiveUserStatusNotification:(NSNotification *)notification {
    KUser *user = (KUser *)notification.object;
    if([user.remoteStatus isEqualToString:KRemoteCreateSuccessStatus]) {
        [notification.object generateRandomThread];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        UIViewController *inboxView = [storyboard instantiateViewControllerWithIdentifier:@"InboxTableViewController"];
        [self presentViewController:inboxView animated:YES completion:nil];
    }else if([user.remoteStatus isEqualToString:KRemoteCreateFailureStatus]) {
    }
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
