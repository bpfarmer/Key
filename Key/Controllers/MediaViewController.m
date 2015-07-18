//
//  MediaViewController.m
//  Key
//
//  Created by Brendan Farmer on 7/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "MediaViewController.h"
#import <MapKit/MapKit.h>
#import "KPhoto.h"
#import "KPost.h"
#import "KLocation.h"
#import "KAccountManager.h"
#import "KUser.h"

@interface MediaViewController () <MKMapViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) IBOutlet UILabel *timerLabel;
@property (nonatomic) KPhoto *photo;
@property (nonatomic) KLocation *location;

@end

@implementation MediaViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissViews:)];
    tapGestureRecognizer.delegate = self;
    tapGestureRecognizer.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    if(self.post) {
        /*
        if(self.post.attachments.count > 0) {
            if([self.post.attachments.firstObject isKindOfClass:[KPhoto class]]) {
                self.photo = (KPhoto *)self.post.attachments.firstObject;
            }else if([self.post.attachments.firstObject isKindOfClass:[KLocation class]]) {
                self.location = (KLocation *)self.post.attachments.firstObject;
            }
            
            if(self.post.attachments.count > 1) {
                if([self.post.attachments.lastObject isKindOfClass:[KPhoto class]]) {
                    self.photo = (KPhoto *)self.post.attachments.lastObject;
                }else if([self.post.attachments.lastObject isKindOfClass:[KLocation class]]) {
                    self.location = (KLocation *)self.post.attachments.lastObject;
                }
            }
            
            if(self.photo) {
                [self setupImageViewWithImage:self.photo.media];
            }else if(self.location) {
                [self setupMapViewWithLocation:self.location.location];
            }
        }*/
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupMapViewWithLocation:(CLLocation *)location {
    self.location = nil;
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.mapView.zoomEnabled = NO;
    self.mapView.scrollEnabled = NO;
    self.mapView.rotateEnabled = NO;
    self.mapView.showsPointsOfInterest = NO;
    self.mapView.showsBuildings = NO;
    self.mapView.clearsContextBeforeDrawing = YES;
    self.mapView.centerCoordinate = location.coordinate;
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    [annotation setCoordinate:location.coordinate];
    [annotation setTitle:self.post.author.username];
    [self.mapView addAnnotation:annotation];
    MKCoordinateRegion region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(0.1, 0.1));
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:region];
    [self.mapView setRegion:adjustedRegion animated:YES];
    self.mapView = (MKMapView *)[self addTapGestureRecognizerToView:self.mapView];
    [self.view addSubview:self.mapView];
}

- (void)setupImageViewWithImage:(NSData *)image {
    self.imageView.image = [UIImage imageWithData:image];
    self.imageView = (UIImageView *)[self addTapGestureRecognizerToView:self.imageView];
    [self.view addSubview:self.imageView];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (UIView *)addTapGestureRecognizerToView:(UIView *)view {
    UIView *overlayView = [[UIView alloc] initWithFrame:view.frame];
    overlayView.backgroundColor = [UIColor clearColor];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissViews:)];
    tapGestureRecognizer.delegate = self;
    tapGestureRecognizer.numberOfTouchesRequired = 1;
    tapGestureRecognizer.cancelsTouchesInView = YES;
    [overlayView addGestureRecognizer:tapGestureRecognizer];
    [view addSubview:overlayView];
    [view bringSubviewToFront:overlayView];
    return view;
}

- (void)dismissViews:(UITapGestureRecognizer *)sender {
    [self.imageView removeFromSuperview];
    if(self.location) {
        [self setupMapViewWithLocation:self.location.location];
    }else {
        [self dismissViewControllerAnimated:NO completion:nil];
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


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
