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
@class HomeViewController;

@interface InboxViewController : UIViewController

@property (nonatomic, weak) KThread *selectedThread;
@property (nonatomic, strong) HomeViewController *homeViewController;

@end
