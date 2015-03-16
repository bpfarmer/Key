//
//  KSendable.h
//  Key
//
//  Created by Brendan Farmer on 3/9/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kRemotePutSuccessStatus @"KRemoteCreateSuccess"
#define kRemotePutFailureStatus @"KRemoteCreateFailure"
#define kRemotePutNetworkFailureStatus @"KRemoteCreateNetworkFailure"
#define kRemotePutNotification  @"KRemoteCreateNotification"

#define kRemotePostSuccessStatus @"KRemoteUpdateSuccess"
#define kRemotePostFailureStatus @"KRemoteUpdateFailure"
#define kRemotePostNetworkFailureStatus @"KRemoteUpdateNetworkFailure"
#define kRemotePostNotification  @"KRemoteUpdateNotification"

@protocol KSendable <NSObject, NSSecureCoding>

- (void)setUniqueId:(NSString *)uniqueId;
- (void)setRemoteStatus:(NSString *)remoteStatus;
- (NSArray *)keysToSend;
- (NSString *)remoteAlias;

@property (nonatomic) NSString *remoteStatus;

@end
