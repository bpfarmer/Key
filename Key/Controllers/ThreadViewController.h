//
//  ThreadViewController.h
//  Key
//
//  Created by Brendan Farmer on 3/18/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSQMessagesViewController.h"
#import "JSQMessages.h"

@class KThread;

@interface ThreadViewController : JSQMessagesViewController

@property (nonatomic, retain) KThread *thread;
@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@end
