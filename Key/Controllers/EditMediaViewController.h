//
//  EditMediaViewController.h
//  Key
//
//  Created by Brendan Farmer on 6/29/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DismissAndPresentProtocol.h"

@class KThread;

@interface EditMediaViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIImageView *mediaView;
@property (nonatomic,weak) id <DismissAndPresentProtocol> delegate;
@property (nonatomic, strong) NSData *imageData;
@property (nonatomic) BOOL shoudDismiss;
@property (nonatomic) KThread *thread;

@end
