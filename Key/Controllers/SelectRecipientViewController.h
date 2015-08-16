//
//  SelectRecipientViewController.h
//  Key
//
//  Created by Brendan Farmer on 4/29/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KSendable.h"
#import "DismissAndPresentProtocol.h"

@class KPost;
@class KUser;
@class KPhoto;
@class KLocation;

#define kSelectRecipientsForMessage @"message"
#define kSelectRecipientsForPost    @"post"

@interface SelectRecipientViewController : UIViewController

@property (nonatomic,weak) id <DismissAndPresentProtocol> delegate;
@property (nonatomic) NSArray *sendableObjects;
@property (nonatomic) KPost *post;
@property (nonatomic) KUser *currentUser;
@property (nonatomic) NSString *desiredObject;
@property (nonatomic) BOOL ephemeral;

@end
