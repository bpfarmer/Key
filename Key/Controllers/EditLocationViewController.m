//
//  EditLocationViewController.m
//  Key
//
//  Created by Brendan Farmer on 6/29/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "EditLocationViewController.h"
#import "SelectRecipientViewController.h"
#import "KAccountManager.h"
#import "KLocation.h"

@interface EditLocationViewController ()

@property (nonatomic, strong) IBOutlet MKMapView *mapView;

@end

@implementation EditLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.mapView.zoomEnabled = YES;
    self.mapView.scrollEnabled = YES;
    self.mapView.rotateEnabled = YES;
    self.mapView.showsPointsOfInterest = NO;
    self.mapView.showsBuildings = NO;
    self.mapView.clearsContextBeforeDrawing = YES;
    [[KAccountManager sharedManager] refreshCurrentCoordinate];
}

- (void)viewDidAppear:(BOOL)animated {
    if(!self.mapView) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    self.mapView.centerCoordinate = userLocation.location.coordinate;
}

- (IBAction)didPressCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self applyMapViewMemoryFix];
}

- (void)applyMapViewMemoryFix{
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.mapType = MKMapTypeHybrid;
    self.mapView.showsUserLocation = NO;
    self.mapView.delegate = nil;
    [self.mapView removeFromSuperview];
    self.mapView = nil;
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
    [sendableObjects addObject:[[KLocation alloc] initWithUserUniqueId:[KAccountManager sharedManager].uniqueId location:[KAccountManager sharedManager].currentCoordinate]];
    [selectRecipientView setSendableObjects:sendableObjects];
    [self presentViewController:selectRecipientView animated:NO completion:nil];
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
