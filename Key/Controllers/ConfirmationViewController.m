//
//  ConfirmationViewController.m
//  Key
//
//  Created by Brendan Farmer on 10/8/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ConfirmationViewController.h"
#import "QRReadRequest.h"
#import "ShareViewController.h"

@interface ConfirmationViewController ()

@end

@implementation ConfirmationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.opaque = YES;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)approve:(id)sender {
    [self.view removeFromSuperview];
    [QRReadRequest makeRequestWithParameters:@{}];
    [self.shareDelegate performSelector:@selector(didDismissPopup) withObject:nil afterDelay:5.0];
}

@end
