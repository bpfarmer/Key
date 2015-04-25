//
//  ShareViewController.m
//  Key
//
//  Created by Brendan Farmer on 4/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ShareViewController.h"

#define kHomeViewPushSegue @"homeViewPush"
#define kSocialViewPushSegue @"socialViewPush"

@interface ShareViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UISwipeGestureRecognizer *swipeGestureRecognizer;

@end

@implementation ShareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    static BOOL beenHereBefore = NO;
    
    if(beenHereBefore) {
        return;
    }else {
        beenHereBefore = YES;
    }
    
    if([self cameraAvailable] && [self cameraSupportsTakingPhotos]) {
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        controller.sourceType = UIImagePickerControllerSourceTypeCamera;
        NSString *requiredMediaType = (__bridge NSString *)kUTTypeImage;
        controller.mediaTypes = [[NSArray alloc] initWithObjects:requiredMediaType, nil];
        controller.allowsEditing = YES;
        controller.delegate = self;
        //[self presentViewController:controller animated:YES completion:nil];
    }else {
        NSLog(@"Camera is not available");
    }
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
