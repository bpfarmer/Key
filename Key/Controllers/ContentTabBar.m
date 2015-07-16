//
//  ContentTabBar.m
//  Key
//
//  Created by Brendan Farmer on 7/16/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ContentTabBar.h"

@implementation ContentTabBar

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize sizeThatFits = [super sizeThatFits:size];
    sizeThatFits.height = 25;
    return sizeThatFits;
}

@end
