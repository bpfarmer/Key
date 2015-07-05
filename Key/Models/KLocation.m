//
//  KLocation.m
//  Key
//
//  Created by Brendan Farmer on 7/2/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KLocation.h"

@implementation KLocation

- (instancetype)initWithUserUniqueId:(NSString *)userUniqueId location:(CLLocation *)location {
    self = [super init];
    
    if(self) {
        _userUniqueId = userUniqueId;
        _location     = location;
    }
    return self;
}

@end
