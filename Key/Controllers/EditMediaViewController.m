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

@interface EditMediaViewController () <DismissAndPresentProtocol, UIGestureRecognizerDelegate, UITextFieldDelegate>

@property (nonatomic) IBOutlet UIView *overlayView;
@property (nonatomic) IBOutlet UIButton *locationButton;
@property (nonatomic) IBOutlet UIButton *ephemeralButton;
@property (nonatomic) BOOL locationEnabled;
@property (nonatomic) BOOL ephemeral;
@property (nonatomic) BOOL captionShowing;
@property (nonatomic) UITextField *captionTextField;
@property (nonatomic) UIView *captionView;
@property (nonatomic) CGPoint captionOriginalPosition;
@property (nonatomic) BOOL captionDraggable;

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
    [[KAccountManager sharedManager] refreshCurrentCoordinate];
    
    self.overlayView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    
    self.captionShowing = NO;
    
    self.captionTextField.delegate = self;
    
    UITapGestureRecognizer *tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleCaption)];
    [tapRec setCancelsTouchesInView:NO];
    tapRec.delegate = self;
    [self.view addGestureRecognizer:tapRec];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification*)note{
    NSDictionary *userInfo = note.userInfo;
    CGRect finalKeyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    float inputViewFinalYPosition = self.view.bounds.size.height - (finalKeyboardFrame.size.height + 30);
    CGRect inputViewFrame = self.captionView.bounds;
    inputViewFrame.origin.y = inputViewFinalYPosition;
    
    [UIView animateWithDuration:animationDuration animations:^{
        self.captionView.frame = inputViewFrame;
    }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return ![touch.view isKindOfClass:[UIButton class]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self toggleCaption];
    return YES;
}

- (void)keyboardWillHide:(NSNotification*)note{
    NSDictionary *userInfo = note.userInfo;
    NSTimeInterval animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGRect inputViewFrame = self.captionView.bounds;
    inputViewFrame.origin.y = self.view.bounds.size.height;
    
    [UIView animateWithDuration:animationDuration animations:^{
        //self.captionView.frame = inputViewFrame;
    }];
    
}

- (void)toggleCaption {
    if(!self.captionShowing) {
        [self getCaptionView];
        self.captionShowing = YES;
    }else if([self.captionTextField.text isEqualToString:@""]) {
        [self.captionView removeFromSuperview];
        self.captionShowing = NO;
    }else {
        [self.view endEditing:YES];
        self.captionTextField.textAlignment = NSTextAlignmentCenter;
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.textAlignment = NSTextAlignmentLeft;
    self.captionDraggable = NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.captionDraggable = YES;
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

- (IBAction)didPressEphemeral:(id)sender {
    if(!self.ephemeral) {
        self.ephemeral = YES;
        [self.ephemeralButton setTitle:@"Ephemeral On" forState:UIControlStateNormal];
    }else {
        self.ephemeral = NO;
        [self.ephemeralButton setTitle:@"Ephemeral Off" forState:UIControlStateNormal];
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SelectRecipientViewController *selectRecipientView = [[SelectRecipientViewController alloc] initWithNibName:@"SelectRecipientsView" bundle:nil];
        NSMutableArray *sendableObjects = [[NSMutableArray alloc] init];
        
        if(![self.captionTextField.text isEqual:@""]) {
            self.imageData = [self renderImageWithCaption];
        }
        [sendableObjects addObject:[[KPhoto alloc] initWithMedia:self.imageData ephemeral:self.ephemeral]];
        if(self.locationEnabled) {
            [sendableObjects addObject:[[KLocation alloc] initWithUserUniqueId:[KAccountManager sharedManager].uniqueId location:[KAccountManager sharedManager].currentCoordinate]];
        }
        [selectRecipientView setSendableObjects:sendableObjects];
        selectRecipientView.delegate = self;
        selectRecipientView.ephemeral = self.ephemeral;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:selectRecipientView animated:NO completion:nil];
        });
    });
}

- (void)dismissAndPresentViewController:(UIViewController *)viewController {
    [self dismissViewControllerAnimated:NO completion:^{
        if(viewController != nil) [self presentViewController:viewController animated:YES completion:nil];
        else [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (void)dismissAndPresentThread:(KThread *)thread  {}


- (UIView *)getCaptionView {
    self.captionView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height / 2.0, self.view.frame.size.width, 30)];
    [self.captionView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.5f]];
    [self.captionView setOpaque:NO];
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    panRecognizer.delegate = self;
    [self.captionView addGestureRecognizer:panRecognizer];
    [self.captionView setUserInteractionEnabled:YES];
    
    self.captionOriginalPosition = self.captionView.frame.origin;
    self.captionTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.captionView.frame.size.width, self.captionView.frame.size.height)];
    self.captionTextField.delegate = self;
    self.captionTextField.textColor = [UIColor whiteColor];
    [self.captionView addSubview:self.captionTextField];
    [self.captionView bringSubviewToFront:self.captionTextField];
    [self.view addSubview:self.captionView];
    [self.captionTextField becomeFirstResponder];
    return self.captionView;
}

-(void)move:(UIPanGestureRecognizer *)sender {
    if(self.captionDraggable) {
        [self.view bringSubviewToFront:sender.view];
        CGPoint translatedPoint = [(UIPanGestureRecognizer*)sender translationInView:self.view];

        if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
            self.captionOriginalPosition = sender.view.center;
        }

        translatedPoint = CGPointMake(self.view.center.x, self.captionOriginalPosition.y + translatedPoint.y);

        [sender.view setCenter:translatedPoint];

        if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
            CGFloat velocityY = .35*[sender velocityInView:self.view].y;
            CGFloat finalY = translatedPoint.y;
            CGFloat animationDuration = (ABS(velocityY)*.0002)+.2;
            CGPoint finalPoint = CGPointMake(sender.view.center.x, finalY);
            if(CGRectContainsPoint(self.view.frame, finalPoint)) {
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:animationDuration];
                [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
                [UIView setAnimationDelegate:self];
                [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:)];
                [sender.view setCenter:finalPoint];
                [UIView commitAnimations];
                self.captionOriginalPosition = sender.view.center;
            }
        }
    }
}

- (NSData *)renderImageWithCaption {
    [self.mediaView addSubview:self.captionView];
    [self.mediaView bringSubviewToFront:self.captionView];
    UIGraphicsBeginImageContextWithOptions(self.mediaView.bounds.size, self.mediaView.opaque, 0.0);
    [self.mediaView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return UIImageJPEGRepresentation(newImage, 0.8);
}

@end
