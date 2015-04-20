//
//  InboxViewController.h
//  Key
//
//  Created by Brendan Farmer on 4/16/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class KThread;

@interface InboxViewController : UIViewController

@property (nonatomic, weak) KThread *selectedThread;

@end
