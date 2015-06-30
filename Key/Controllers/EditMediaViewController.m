//
//  EditMediaViewController.m
//  Key
//
//  Created by Brendan Farmer on 6/29/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "EditMediaViewController.h"

@interface EditMediaViewController ()

@property (nonatomic) IBOutlet UIView *overlayView;

@end

@implementation EditMediaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mediaView.image = [UIImage imageWithData:self.imageData];
    [self.view addSubview:self.overlayView];
    [self.overlayView setBackgroundColor:[UIColor clearColor]];
    [self.view bringSubviewToFront:self.overlayView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didPressCancel:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)didPressLocation:(id)sender {
    NSLog(@"WANTS TO ADD LOCATION");
}

- (IBAction)didPressPost:(id)sender {
    NSLog(@"WANTS TO POST");
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
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
