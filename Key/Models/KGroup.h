//
//  KGroup.h
//  Key
//
//  Created by Brendan Farmer on 1/17/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "KDatabaseObject.h"

@interface KGroup : KDatabaseObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSArray *users;


@end
