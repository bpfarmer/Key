//
//  ShareViewController.h
//  Key
//
//  Created by Brendan Farmer on 4/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "DismissAndPresentProtocol.h"

@class KThread;

@interface ShareViewController : UIViewController

@property (nonatomic) KThread *thread;
@property (nonatomic,weak) id <DismissAndPresentProtocol> delegate;

- (void)cameraOn;
- (void)cameraOff;

@end
