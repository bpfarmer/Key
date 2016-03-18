//
//  MasterKey.h
//  FreeKey
//
//  Created by Brendan Farmer on 3/4/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SessionKeyBundle;

@interface MasterKey : NSObject

@property (nonatomic, readonly) NSData *keyData;

- (instancetype)initFromKeyBundle:(SessionKeyBundle *)params;

@end
