//
//  ThreadTableViewController.h
//  Key
//
//  Created by Loren on 2/5/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KThread;

@interface ThreadTableViewController : UITableViewController

@property (nonatomic, retain) KThread *thread;

@end
