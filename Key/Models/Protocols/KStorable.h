//
//  KStorable.h
//  Key
//
//  Created by Brendan Farmer on 4/29/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KStorable

@property (nonatomic, readwrite) NSString *uniqueId;

- (void) save;
- (NSString *) collection;

@end
