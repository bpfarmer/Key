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

/*
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}*/

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)createNewUser:(id)sender {
    KUser *user = [[KUser alloc] initWithUsername:self.usernameText.text];
    [user registerPassword:self.passwordText.text];
    
    NSLog(@"%@ %@", user.username, self.passwordText.text);
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