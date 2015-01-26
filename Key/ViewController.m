//
//  ViewController.m
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ViewController.h"
#import "KUser.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    KUser *user = [[KUser alloc] init];
    NSString *username = @"username3";
    [user registerUsername:username password:@"12345"];
    //[realm addNotificationBlock:^(NSString *note, RLMRealm * realm) {
        //[self tryFinishRegistration:username realm:realm];
    //}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
