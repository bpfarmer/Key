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
                                                 name:kUserRegistrationStatusNotification
                                               object:nil];
    dispatch_queue_t registrationQueue= dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(registrationQueue, ^{
        KUser *user = [[KUser alloc] initWithUsername:self.usernameText.text];
        [user registerAccountWithPassword:self.passwordText.text];
    });
    NSLog(@"NOT BLOCKING");
}

- (void)receiveUserStatusNotification:(NSNotification *)notification {
    
    NSString *status = [notification.object performSelector:@selector(status)];
    if([status isEqualToString:kUserRegisterUsernameSuccessStatus]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        UIViewController *inboxView = [storyboard instantiateViewControllerWithIdentifier:@"InboxViewController"];
        [self presentViewController:inboxView animated:YES completion:nil];
    }else if([status isEqualToString:kUserRegisterUsernameFailureStatus]) {
        
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
