//
//  KPhoto.m
//  Key
//
//  Created by Brendan Farmer on 7/2/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KPhoto.h"

@implementation KPhoto

- (instancetype)initWithMedia:(NSData *)media ephemeral:(BOOL)ephemeral {
    self = [super init];
    
    if(self) {
        _media     = media;
        _ephemeral = ephemeral;
    }
    
    return self;
}

@end
