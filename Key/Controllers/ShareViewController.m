#import "ShareViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "HomeViewController.h"
#import "Attachment.h"
#import "EditMediaViewController.h"
#import "DismissAndPresentProtocol.h"
#import "QRReadRequest.h"
#import "UIAlertController+Orientation.h"
#import "ConfirmationViewController.h"
#import <25519/Ed25519.h>
#import <25519/Curve25519.h>
#import "KAccountManager.h"
#import "KUser.h"

#define kHomeViewPushSegue @"homeViewPush"
#define kSocialViewPushSegue @"socialViewPush"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface ShareViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, DismissAndPresentProtocol, AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) IBOutlet UIView *cameraOverlayView;

@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) UIView *cameraPreviewFeedView;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic) BOOL flashOn;
@property (nonatomic) BOOL readQRCode;
@property (nonatomic) NSString *decodedQR;
@property (nonatomic, strong) IBOutlet UIButton *backButton;
@property (nonatomic, strong) ConfirmationViewController *confirmationPopup;

@property (nonatomic) UILabel *noCameraInSimulatorMessage;


@end

@implementation ShareViewController {
    BOOL _simulatorIsCameraRunning;
    BOOL _cameraRunning;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.noCameraInSimulatorMessage.hidden = !TARGET_IPHONE_SIMULATOR;
    self.readQRCode = NO;
    CGRect frame = [UIScreen mainScreen].bounds;
    frame.origin.x = frame.size.width;
    self.view.frame = frame;
    self.confirmationPopup = [[ConfirmationViewController alloc] init];
    self.confirmationPopup.shareDelegate = self;
    self.confirmationPopup.view.center = CGPointMake(self.view.frame.size.width  / 2, self.view.frame.size.height / 2);
    self.confirmationPopup.view.layer.cornerRadius = 5;
    self.confirmationPopup.view.layer.shadowOpacity = 0.8;
    self.confirmationPopup.view.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    if(!self.thread) self.backButton.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startCamera];
    if (![self.view.subviews containsObject:self.cameraOverlayView]) {
        CGRect frame = self.cameraOverlayView.frame;
        frame.size.height = frame.size.height - 85;
        self.cameraOverlayView.frame = frame;
        [self.view addSubview:self.cameraOverlayView];
        [self.cameraOverlayView setBackgroundColor:[UIColor clearColor]];
        [self.view bringSubviewToFront:self.cameraOverlayView];
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [self stopCamera];
    self.readQRCode = NO;
}

- (UILabel *)noCameraInSimulatorMessage {
    if (!_noCameraInSimulatorMessage) {
        CGFloat labelWidth = self.view.bounds.size.width * 0.75f;
        CGFloat labelHeight = 60;
        _noCameraInSimulatorMessage = [[UILabel alloc] initWithFrame:CGRectMake(self.view.center.x - labelWidth/2.0f, self.view.bounds.size.height - 75 - labelHeight, labelWidth, labelHeight)];
        _noCameraInSimulatorMessage.numberOfLines = 0; // wrap
        //_noCameraInSimulatorMessage.text = @"No camera in the simulator...";
        _noCameraInSimulatorMessage.textColor = [UIColor whiteColor];
        _noCameraInSimulatorMessage.backgroundColor = [UIColor clearColor];
        _noCameraInSimulatorMessage.hidden = YES;
        _noCameraInSimulatorMessage.shadowOffset = CGSizeMake(1, 1);
        _noCameraInSimulatorMessage.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:_noCameraInSimulatorMessage];
    }
    
    return _noCameraInSimulatorMessage;
}

- (void)dismissAndPresentThread:(KThread *)thread {
    
}

- (void)cameraOn {
    [self startCamera];
}

- (void)cameraOff {
    [self stopCamera];
}

- (void)startCamera {
    if (TARGET_IPHONE_SIMULATOR) {
        _simulatorIsCameraRunning = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self cameraStartedRunning];
        });
        return;
    }
    
    if (!self.cameraPreviewFeedView) {
        self.cameraPreviewFeedView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        if (![self.view.subviews containsObject:self.cameraPreviewFeedView]) {
            [self.view addSubview:self.cameraPreviewFeedView];
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
                
                AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
                [self.captureSession addOutput:captureMetadataOutput];
                dispatch_queue_t dispatchQueue;
                dispatchQueue = dispatch_queue_create("barcodeReaderQueue", NULL);
                [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
                [captureMetadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeQRCode]];
                
                NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
                
                [notificationCenter addObserver:self selector:@selector(onVideoError:) name:AVCaptureSessionRuntimeErrorNotification object:self.captureSession];
                
                    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8")) {
                        self.captureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
                        self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                        self.captureVideoPreviewLayer.frame = self.cameraPreviewFeedView.bounds;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.cameraPreviewFeedView.layer addSublayer:self.captureVideoPreviewLayer];
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.captureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
                            self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                            self.captureVideoPreviewLayer.frame = self.cameraPreviewFeedView.bounds;
                            [self.cameraPreviewFeedView.layer addSublayer:self.captureVideoPreviewLayer];
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
            NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"beach" ofType:@"jpg"];
            NSLog(@"IMAGE PATH: %@", imagePath);
            NSData *img = [NSData dataWithContentsOfFile:imagePath];
            [self didTakePhoto:img];
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
                                                           completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
                                                               if(imageSampleBuffer) {
             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
             
             [self didTakePhoto:imageData];
                                                               }
         }];
    });
}

- (void)cameraStartedRunning {
    _cameraRunning = YES;
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

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position) return device;
    }
    return nil;
}

- (BOOL)cameraAvailable {
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] || [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

- (BOOL)cameraSupportsTakingPhotos {
    return [self cameraSupportsMedia:(__bridge NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypeCamera];
}

- (IBAction)toggleFlash:(id)sender {
    if(self.captureSession) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            AVCaptureInput *currentCameraInput = [self.captureSession.inputs objectAtIndex:0];
            AVCaptureDevice *currentDevice = ((AVCaptureDeviceInput *)currentCameraInput).device;
            
            if(currentDevice.flashAvailable) {
                [self.captureSession beginConfiguration];
                [self.captureSession removeInput:currentCameraInput];
                
                [currentDevice lockForConfiguration:nil];
                if(currentDevice.flashMode == AVCaptureFlashModeOn) {
                    [currentDevice setFlashMode:AVCaptureFlashModeOff];
                }else {
                    if([currentDevice isFlashModeSupported:AVCaptureFlashModeOn]) {
                        [currentDevice setFlashMode:AVCaptureFlashModeOn];
                    }
                }
                [currentDevice unlockForConfiguration];
                NSError *error = nil;
                AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:currentDevice error:&error];
                if(!newVideoInput || error) {
                    NSLog(@"ERROR CAPTURING DEVICE INPUT: %@", error.localizedDescription);
                }else {
                    [self.captureSession addInput:newVideoInput];
                }
                
                [self.captureSession commitConfiguration];
            }
        });
    }
}

- (IBAction)toggleOrientation:(id)sender {
    if(self.captureSession) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.captureSession beginConfiguration];
            
            AVCaptureInput *currentCameraInput = [self.captureSession.inputs objectAtIndex:0];
            [self.captureSession removeInput:currentCameraInput];
            
            AVCaptureDevice *newCamera = nil;
            if(((AVCaptureDeviceInput *)currentCameraInput).device.position == AVCaptureDevicePositionBack) {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
            }else {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
            }
            
            NSError *error = nil;
            AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:&error];
            if(!newVideoInput || error) {
                NSLog(@"ERROR CAPTURING DEVICE INPUT: %@", error.localizedDescription);
            }else {
                [self.captureSession addInput:newVideoInput];
            }
            
            [self.captureSession commitConfiguration];
        });
    }
}

- (IBAction)didPressBack:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)didDismissPopup {
    self.readQRCode = NO;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects != nil && [metadataObjects count] > 0 && !self.readQRCode) {
        self.readQRCode = YES;
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        self.decodedQR = metadataObj.stringValue;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view addSubview:self.confirmationPopup.view];
            [self.view bringSubviewToFront:self.confirmationPopup.view];
        });
    }
}

- (void)displayApprovalAlert {
    dispatch_async(dispatch_get_main_queue(), ^{
        if([UIAlertController class]) {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Approve Transaction?"
                                                                           message:@"Pay $1 to The New York Times?"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* approveAction = [UIAlertAction actionWithTitle:@"Approve" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [self makeAuthenticationRequest];
                                                                    }];
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Decline" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            [alert addAction:approveAction];
            [alert addAction:cancelAction];
            [self presentViewController:alert animated:YES completion:nil];
        }else {
            UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Approve Transaction?"
                                                             message:@"Pay $1 to The New York Times?"
                                                            delegate:self
                                                   cancelButtonTitle:@"Decline"
                                                   otherButtonTitles: nil];
            [alert addButtonWithTitle:@"Approve"];
            [alert show];
        }
    });
}

- (void)makeAuthenticationRequest {
    KUser *currentUser = [KAccountManager sharedManager].user;
    NSData *signature = [Ed25519 sign:[self.decodedQR dataUsingEncoding:NSUTF8StringEncoding] withKeyPair:currentUser.identityKey];
    [QRReadRequest makeRequestWithParameters:@{@"signature" : signature, @"public_key" : currentUser.identityKey.publicKey}];
    NSLog(@"%@", @{@"Amount" : @"$8.78", @"Sender" : currentUser.username, @"Recipient" : @"amazon", @"Transaction ID" : self.decodedQR, @"Signature" : signature});
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    self.readQRCode = NO;
}

- (void)didTakePhoto:(NSData *)photoData {
    [self stopCamera];
    EditMediaViewController *editMediaView  = [[EditMediaViewController alloc] initWithNibName:@"EditMediaView" bundle:nil];
    editMediaView.imageData                 = photoData;
    editMediaView.delegate                  = self;
    editMediaView.thread                    = self.thread;
    self.thread                             = nil;
    if(self.parentViewController)
        [self.parentViewController presentViewController:editMediaView animated:NO completion:nil];
    else
        [self.delegate dismissAndPresentViewController:editMediaView];
}

- (void)dismissAndPresentViewController:(UIViewController *)viewController {
    [self dismissViewControllerAnimated:NO completion:^{
        [self presentViewController:viewController animated:YES completion:nil];
    }];
}

- (IBAction)captureImage:(id)sender {
    [self takePhoto];
}

@end