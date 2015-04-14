//
//  KAccountManager.h
//  Key
//
//  Created by Brendan Farmer on 2/1/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KUser;
@class TOCFuture;

@interface KAccountManager : NSObject

@property (nonatomic) NSString *uniqueId;
@property (nonatomic) KUser *user;

+ (instancetype)sharedManager;

- (TOCFuture *)asyncGetFeed;

@end
