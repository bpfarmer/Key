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
        if(self.post.attachments.count > 0) {
            NSLog(@"SHOULD HAVE ATTACHMENTS");
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
        }
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
    self.coordinate = location.coordinate;
    self.mapZoom = 1;
    MKCoordinateRegion region = MKCoordinateRegionMake(self.coordinate, MKCoordinateSpanMake(80.0 , 80.0));
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:region];
    [self.mapView setRegion:adjustedRegion animated:YES];
    self.mapView = (MKMapView *)[self addTapGestureRecognizerToView:self.mapView];
    [self addAddressCaptionWithLocation:location];
    [self.view addSubview:self.mapView];
}

- (void)addAddressCaptionWithLocation:(CLLocation *)location {
    UIView *captionView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 60, self.view.frame.size.width, 30)];
    [captionView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.5f]];
    [captionView setOpaque:NO];
    
    UILabel *captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    captionLabel.textAlignment = NSTextAlignmentCenter;
    captionLabel.textColor = [UIColor whiteColor];
    
    CLGeocoder *ceo = [[CLGeocoder alloc]init];
    CLLocation *loc = [[CLLocation alloc]initWithCoordinate:location.coordinate altitude:location.altitude horizontalAccuracy:location.horizontalAccuracy verticalAccuracy:location.verticalAccuracy course:location.course speed:location.speed timestamp:location.timestamp];
    
    [ceo reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = [placemarks objectAtIndex:0];
        NSMutableArray *locationComponents = [NSMutableArray new];
        [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
        
        if(placemark.name) [locationComponents addObject:placemark.name];
        NSArray *addressComponents = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"][1] componentsSeparatedByString:@" "];
        [locationComponents addObject:[NSString stringWithFormat:@"%@ %@", addressComponents[0], addressComponents[1]]];
        captionLabel.text = [locationComponents componentsJoinedByString:@", "];
        [captionView addSubview:captionLabel];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.mapView addSubview:captionView];
            [self.mapView bringSubviewToFront:captionView];
        });
    }];
}

- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered {
    if(self.mapZoom > 0 && self.mapZoom < 5) [NSTimer scheduledTimerWithTimeInterval:1.1 target:self selector:@selector(zoomMapRegion) userInfo:nil repeats:NO];
    else NSLog(@"MAP ZOOM TERMINATED: %u", self.mapZoom);
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
}

- (double)coordinateSpan:(NSUInteger)mapZoom {
    NSArray *coordinateSpans = @[[NSNumber numberWithDouble:20.0],
                                 [NSNumber numberWithDouble:5.0],
                                 [NSNumber numberWithDouble:0.5],
                                 [NSNumber numberWithDouble:0.08],
                                 [NSNumber numberWithDouble:0.03]];
    if(self.mapZoom < 5) return [[coordinateSpans objectAtIndex:mapZoom] doubleValue];
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
