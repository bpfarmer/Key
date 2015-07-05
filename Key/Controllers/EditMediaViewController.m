//
//  EditMediaViewController.m
//  Key
//
//  Created by Brendan Farmer on 6/29/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "EditMediaViewController.h"
#import "SelectRecipientViewController.h"
#import "KPhoto.h"
#import "KLocation.h"
#import "KAccountManager.h"

@interface EditMediaViewController ()

@property (nonatomic) IBOutlet UIView *overlayView;
@property (nonatomic) IBOutlet UIButton *locationButton;
@property (nonatomic) BOOL locationEnabled;
@property (nonatomic) BOOL ephemeral;
@property (nonatomic) BOOL toDismiss;

@end

@implementation EditMediaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mediaView.image = [UIImage imageWithData:self.imageData];
    [self.view addSubview:self.overlayView];
    [self.overlayView setBackgroundColor:[UIColor clearColor]];
    [self.view bringSubviewToFront:self.overlayView];
    self.ephemeral = NO;
    self.locationEnabled = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didPressCancel:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)didPressLocation:(id)sender {
    if(!self.locationEnabled) {
        self.locationEnabled = YES;
        [self.locationButton setTitle:@"Location On" forState:UIControlStateNormal];
    }else {
        self.locationEnabled = NO;
        [self.locationButton setTitle:@"Location Off" forState:UIControlStateNormal];
    }
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

- (IBAction)didPressPost:(id)sender {
    SelectRecipientViewController *selectRecipientView = [[SelectRecipientViewController alloc] initWithNibName:@"SelectRecipientsView" bundle:nil];
    NSMutableArray *sendableObjects = [[NSMutableArray alloc] init];
    [sendableObjects addObject:[[KPhoto alloc] initWithMedia:self.imageData ephemeral:self.ephemeral]];
    if(self.locationEnabled) {
        [sendableObjects addObject:[[KLocation alloc] initWithUserUniqueId:[KAccountManager sharedManager].uniqueId location:[KAccountManager sharedManager].currentCoordinate]];
    }
    [selectRecipientView setSendableObjects:sendableObjects];
    self.toDismiss = YES;
    [self presentViewController:selectRecipientView animated:NO completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    if(self.toDismiss) {
        [self dismissViewControllerAnimated:YES completion:nil];
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
