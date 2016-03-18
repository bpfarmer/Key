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
@property (nonatomic) int mapZoom;
@property (nonatomic) CLLocationCoordinate2D coordinate;

@end

@implementation MediaViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissViews:)];
    tapGestureRecognizer.delegate = self;
    tapGestureRecognizer.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    if(self.post) {
        self.post = [KPost findById:self.post.uniqueId];
        [self.post setReadAt:[NSDate date]];
        [self.post save];
        NSLog(@"POST READ AT: %@", self.post.readAt);
        NSLog(@"ATTACHMENT IDS: %@", self.post.attachmentIds);
        NSLog(@"EPHEMERAL: %hhd", self.post.ephemeral);
        if(self.post.attachments.count > 0) {
            for(KDatabaseObject <KAttachable> *attachment in self.post.attachments) {
                if([attachment isKindOfClass:[KPhoto class]]) self.photo = (KPhoto *)attachment;
                else if([attachment isKindOfClass:[KLocation class]]) self.location = (KLocation *)attachment;
            }
            if(self.photo) {
                [self setupImageViewWithImage:self.photo.media];
            }else if(self.location) {
                [self setupMapViewWithLocation:self.location];
            }
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupMapViewWithLocation:(KLocation *)postLocation {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        CLLocation *location = postLocation.location;
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
        self.coordinate = location.coordinate;
        self.mapZoom = 1;
        MKCoordinateRegion region = MKCoordinateRegionMake(self.coordinate, MKCoordinateSpanMake(60.0, 60.0));
        MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:region];
        [self.mapView setRegion:adjustedRegion animated:YES];
        self.mapView = (MKMapView *)[self addTapGestureRecognizerToView:self.mapView];
        [self.mapView addAnnotation:annotation];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addAddressCaptionWithLocation:postLocation];
            [self.view addSubview:self.mapView];
        });
    });
}

- (void)addAddressCaptionWithLocation:(KLocation *)location {
    UIView *captionView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 30, self.view.frame.size.width, 30)];
    [captionView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.5f]];
    [captionView setOpaque:NO];
    
    UILabel *captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    captionLabel.textAlignment = NSTextAlignmentCenter;
    captionLabel.textColor = [UIColor whiteColor];
    captionLabel.text = location.formattedAddress;
    [captionView addSubview:captionLabel];

    [self.mapView addSubview:captionView];
    [self.mapView bringSubviewToFront:captionView];
}

- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered {
    if(self.mapZoom > 0 && self.mapZoom < 4) [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(zoomMapRegion) userInfo:nil repeats:NO];
    else NSLog(@"MAP ZOOM TERMINATED: %u", self.mapZoom);
}

- (double)coordinateSpan:(NSUInteger)mapZoom {
    NSArray *coordinateSpans = @[[NSNumber numberWithDouble:40.0],
                                 [NSNumber numberWithDouble:10.0],
                                 [NSNumber numberWithDouble:1.0],
                                 [NSNumber numberWithDouble:0.05]];
    if(self.mapZoom < 4) return [[coordinateSpans objectAtIndex:mapZoom] doubleValue];
    else return [coordinateSpans.lastObject doubleValue];
}

- (void)viewWillDisappear:(BOOL)animated {
    self.mapZoom = 0;
}

- (void)zoomMapRegion {
    NSLog(@"ZOOMING MAP WITH MAP ZOOM %u", self.mapZoom);
    MKCoordinateRegion region = MKCoordinateRegionMake(self.coordinate, MKCoordinateSpanMake([self coordinateSpan:self.mapZoom], [self coordinateSpan:self.mapZoom]));
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:region];
    [self.mapView setRegion:adjustedRegion animated:YES];
    self.mapZoom = self.mapZoom + 1;
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
        [self setupMapViewWithLocation:self.location];
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

@end
