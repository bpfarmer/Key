//
//  NeedsRecipientsProtocol.h
//  Key
//
//  Created by Brendan Farmer on 8/31/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KDatabaseObject;

@protocol NeedsRecipientsProtocol <NSObject>

- (void)setRecipientIds:(NSArray *)recipientIds;
- (void)setEphemeral:(BOOL)ephemeral;
- (void)didCancel;
- (BOOL)canSharePersistently;
- (BOOL)canSendToEveryone;

@end
