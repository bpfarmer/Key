//
//  KThreadable.h
//  Key
//
//  Created by Brendan Farmer on 8/27/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KThread;

@protocol KThreadable

@property (nonatomic) NSString *authorId;
@property (nonatomic) NSDate   *createdAt;
@property (nonatomic) NSString *threadId;

@end