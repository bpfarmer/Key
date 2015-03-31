//
//  PushManager.h
//  Key
//
//  Created by Brendan Farmer on 3/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PushManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic) NSData *pushToken;

@end
