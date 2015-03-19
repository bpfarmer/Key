//
//  ThreadViewController.h
//  Key
//
//  Created by Brendan Farmer on 3/18/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KThread;

@interface ThreadViewController : UIViewController

@property (nonatomic, retain) KThread *thread;

@end
