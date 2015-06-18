//
//  ShareViewController.m
//  Key
//
//  Created by Brendan Farmer on 4/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ShareViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "HomeViewController.h"

#define kHomeViewPushSegue @"homeViewPush"
#define kSocialViewPushSegue @"socialViewPush"

@interface ShareViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) UIView *cameraPreviewFeedView;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

@property (nonatomic) UILabel *noCameraInSimulatorMessage;

@property (nonatomic, strong) UISwipeGestureRecognizer *swipeGestureRecognizer;

@end

@implementation ShareViewController {
    BOOL _simulatorIsCameraRunning;
    BOOL _cameraRunning;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.noCameraInSimulatorMessage.hidden = !TARGET_IPHONE_SIMULATOR;
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:singleFingerTap];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self stopCamera];
}

- (UILabel *)noCameraInSimulatorMessage {
    if (!_noCameraInSimulatorMessage) {
        CGFloat labelWidth = self.view.bounds.size.width * 0.75f;
        CGFloat labelHeight = 60;
        _noCameraInSimulatorMessage = [[UILabel alloc] initWithFrame:CGRectMake(self.view.center.x - labelWidth/2.0f, self.view.bounds.size.height - 75 - labelHeight, labelWidth, labelHeight)];
        _noCameraInSimulatorMessage.numberOfLines = 0; // wrap
        _noCameraInSimulatorMessage.text = @"No camera in the simulator...";
        _noCameraInSimulatorMessage.backgroundColor = [UIColor clearColor];
        _noCameraInSimulatorMessage.hidden = YES;
        _noCameraInSimulatorMessage.textColor = [UIColor blackColor];
        _noCameraInSimulatorMessage.shadowOffset = CGSizeMake(1, 1);
        _noCameraInSimulatorMessage.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:_noCameraInSimulatorMessage];
    }
    
    return _noCameraInSimulatorMessage;
}

- (void)startCamera
{
    if (TARGET_IPHONE_SIMULATOR) {
        _simulatorIsCameraRunning = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self cameraStartedRunning];
        });
        return;
    }
    
    if (!self.cameraPreviewFeedView) {
        HomeViewController *homeViewController = (HomeViewController *)self.parentViewController;
        CGRect cameraFrame = self.view.frame;
        self.cameraPreviewFeedView = [[UIView alloc] initWithFrame:cameraFrame];
        self.cameraPreviewFeedView.center = homeViewController.scrollView.center;
        self.cameraPreviewFeedView.backgroundColor = [UIColor blackColor];

        if (![homeViewController.scrollView.subviews containsObject:self.cameraPreviewFeedView]) {
            [homeViewController.scrollView.subviews[1] addSubview:self.cameraPreviewFeedView];
        }
    }
    
    if (![self isCameraRunning]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            
            if (!self.captureSession) {
                
                self.captureSession = [AVCaptureSession new];
                self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
                
                NSError *error = nil;
                AVCaptureDeviceInput *newVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                if (!newVideoInput) {
                    NSLog(@"ERROR: trying to open camera: %@", error);
                }
                
                AVCaptureStillImageOutput *newStillImageOutput = [AVCaptureStillImageOutput new];
                NSDictionary *outputSettings = @{ AVVideoCodecKey : AVVideoCodecJPEG };
                [newStillImageOutput setOutputSettings:outputSettings];
                
                if ([self.captureSession canAddInput:newVideoInput]) {
                    [self.captureSession addInput:newVideoInput];
                }
                
                if ([self.captureSession canAddOutput:newStillImageOutput]) {
                    [self.captureSession addOutput:newStillImageOutput];
                    self.stillImageOutput = newStillImageOutput;
                }
                
                NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
                
                [notificationCenter addObserver:self selector:@selector(onVideoError:) name:AVCaptureSessionRuntimeErrorNotification object:self.captureSession];
                
                if (!self.captureVideoPreviewLayer) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.captureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
                        self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                        self.captureVideoPreviewLayer.frame = self.cameraPreviewFeedView.bounds;
                        [self.cameraPreviewFeedView.layer insertSublayer:self.captureVideoPreviewLayer atIndex:0];
                    });
                }
            }
            
            // this will block the thread until camera is started up
            [self.captureSession startRunning];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self cameraStartedRunning];
            });
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self cameraStartedRunning];
        });
    }
}

- (void)stopCamera
{
    if (TARGET_IPHONE_SIMULATOR) {
        _simulatorIsCameraRunning = NO;
        return;
    }
    
    if (self.captureSession && [self.captureSession isRunning]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
            [self.captureSession stopRunning];
        });
    }
}

- (BOOL)isCameraRunning
{
    if (TARGET_IPHONE_SIMULATOR) return _simulatorIsCameraRunning;
    
    if (!self.captureSession) return NO;
    
    return self.captureSession.isRunning;
}

- (void)onVideoError:(NSNotification *)notification
{
    NSLog(@"Video error: %@", notification.userInfo[AVCaptureSessionErrorKey]);
}

- (void)takePhoto
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (TARGET_IPHONE_SIMULATOR) {
            [self didTakePhoto: [UIImage imageNamed:@"Simulator_OriginalPhoto@2x.jpg"]];
            return;
        }
        
        AVCaptureConnection *videoConnection = nil;
        for (AVCaptureConnection *connection in self.stillImageOutput.connections)
        {
            for (AVCaptureInputPort *port in [connection inputPorts])
            {
                if ([[port mediaType] isEqual:AVMediaTypeVideo] )
                {
                    videoConnection = connection;
                    break;
                }
            }
            if (videoConnection)
            {
                break;
            }
        }
        
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                           completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
         {
             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
             
             [self didTakePhoto: [UIImage imageWithData: imageData]];
         }];
    });
}

//The event handling method
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    
    [self takePhoto];
    
}

- (void)cameraStartedRunning {
    _cameraRunning = YES;
    NSLog(@"CAMERA IS RUNNING");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self startCamera];
}

- (BOOL)cameraSupportsMedia:(NSString *)mediaType sourceType:(UIImagePickerControllerSourceType)sourceType {
    __block BOOL result = NO;
    
    if([mediaType length] == 0)
        return NO;
    
    NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
    
    [availableMediaTypes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSString *availableMediaType = (NSString *)obj;
        if([mediaType isEqualToString:availableMediaType]) {
            result = YES;
            *stop = YES;
        }
    }];
    return result;
}

- (void)didTakePhoto:(UIImage *)photo {
    NSLog(@"TOOK THAT PHOTO!");
}

- (BOOL)cameraAvailable {
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] || [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

- (BOOL)cameraSupportsTakingPhotos {
    return [self cameraSupportsMedia:(__bridge NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypeCamera];
}

- (void)handleSwipes:(UISwipeGestureRecognizer *)paramSender {
    if(paramSender.direction & UISwipeGestureRecognizerDirectionRight) {
        [self performSegueWithIdentifier:kSocialViewPushSegue sender:self];
    }
    if(paramSender.direction & UISwipeGestureRecognizerDirectionLeft) {
        [self performSegueWithIdentifier:kHomeViewPushSegue sender:self];
    }
}


@end
