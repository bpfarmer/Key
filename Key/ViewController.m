//
//  ViewController.m
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ViewController.h"
#import "KRSACryptor.h"
#import "KRSACryptorKeyPair.h"
#import "KError.h"
#import "KKeyPair.h"
#import "KUser.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    KUser *user = [[KUser alloc] init];
    [user addObserver:self forKeyPath:NSStringFromSelector(@selector(status)) options:0 context:NULL];
    [user registerUsername:@"brendan" password:@"12345"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - User Observers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([object isKindOfClass:[KUser class]]) {
        if([keyPath isEqualToString:NSStringFromSelector(@selector(status))]) {
            if([[object valueForKey:keyPath] isEqualToString:kUserRegisterUsernameSuccessStatus]) {
                [object addObserver:object forKeyPath:NSStringFromSelector(@selector(passwordCrypt)) options:0 context:NULL];
                [object removeObserver:object forKeyPath:NSStringFromSelector(@selector(publicId))];
            }else if([[object valueForKey:keyPath] isEqualToString:kUserRegisterUsernameFailureStatus]) {
                NSLog(@"Username taken");
            }
        }else if([keyPath isEqualToString:NSStringFromSelector(@selector(passwordCrypt))]) {
            [object remoteFinishRegistration];
            [object removeObserver:object forKeyPath:NSStringFromSelector(@selector(passwordCrypt))];
        }
    }
}

@end
