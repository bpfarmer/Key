//
//  KYapDatabaseView.h
//  Key
//
//  Created by Brendan Farmer on 2/5/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KYapDatabaseView : NSObject

extern NSString *KInboxGroup;
extern NSString *KArchiveGroup;
extern NSString *KUnreadIncomingMessagesGroup;

extern NSString *KThreadDatabaseViewExtensionName;
extern NSString *KMessageDatabaseViewExtensionName;
extern NSString *KUnreadDatabaseViewExtensionName;

+ (BOOL)registerThreadDatabaseView;
+ (BOOL)registerUnreadDatabaseView;

@end
