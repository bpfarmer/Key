//
//  registrationViewController.m
//  Key
//
//  Created by Loren on 1/27/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "RegistrationViewController.h"
#import "KUser.h"

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
    KUser *user = [[KUser alloc] initWithUsername:@"username3" password:@"password"];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveUserStatusNotification:)
                                                 name:@"UserStatusNotification"
                                               object:nil];
    NSLog(@"NOT BLOCKING");
}

- (void)receiveUserStatusNotification:(NSNotification *)notification {
    
    NSString *status = [notification.object performSelector:@selector(status)];
    if([status isEqualToString:kUserRegisterUsernameSuccessStatus]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle: nil];
        UIViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"IDENTIFIER_OF_YOUR_VIEWCONTROLLER"];
        [self presentViewController:vc animated:YES completion:nil];
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
