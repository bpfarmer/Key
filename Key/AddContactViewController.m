//
//  AddContactViewController.m
//  Key
//
//  Created by Brendan Farmer on 1/29/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "AddContactViewController.h"
#import "KUser.h"
#import "KAccountManager.h"

@interface AddContactViewController ()

@end

@implementation AddContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addContact:(id)sender {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveUserStatusNotification:)
                                                 name:kUserGetRemoteStatusNotification
                                               object:nil];
    dispatch_queue_t registrationQueue= dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(registrationQueue, ^{
        [[KAccountManager currentUser] addContact:[[KUser alloc] initFromRemoteWithUsername:self.usernameText.text]];
    });
    NSLog(@"NOT BLOCKING");
}

- (void)receiveUserStatusNotification:(NSNotification *)notification {
    NSString *status = [notification.object performSelector:@selector(status)];
    if([status isEqualToString:kUserGetRemoteUserSuccessStatus]) {
        NSLog(@"Successfully Retrieved User");
    }else if([status isEqualToString:kUserGetRemoteUserFailureStatus]) {
        NSLog(@"Failed to Retrieve User");
    }
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
