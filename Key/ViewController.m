//
//  ViewController.m
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ViewController.h"
#import "KUser.h"
#import "KStorageManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    KUser *user = [[KUser alloc] initWithUsername:@"username3" password:@"password"];
    [self addObserver:user forKeyPath:NSStringFromSelector(@selector(status)) options:0 context:NULL];
    NSLog(@"NOT BLOCKING");
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[KUser class]]) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(status))]) {
            NSLog(@"FANTASTIC!");
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
