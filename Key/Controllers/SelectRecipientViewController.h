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
#import "KTableViewController.h"
#import "NeedsRecipientsProtocol.h"

@class KPost;
@class KUser;
@class KPhoto;
@class KLocation;

#define kSelectRecipientsForMessage @"message"
#define kSelectRecipientsForPost    @"post"

@interface SelectRecipientViewController : KTableViewController

@property (nonatomic, weak) id <DismissAndPresentProtocol> delegate;
@property (nonatomic, weak) id <NeedsRecipientsProtocol> sendingDelegate;
@property (nonatomic) KUser *currentUser;
@property (nonatomic) KDatabaseObject *sendableObject;
@property (nonatomic) NSArray *attachableObjects;
@property (nonatomic) BOOL ephemeral;

@end
