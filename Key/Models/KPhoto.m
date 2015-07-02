//
//  KPhoto.m
//  Key
//
//  Created by Brendan Farmer on 7/2/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KPhoto.h"

@implementation KPhoto

- (instancetype)initWithFilename:(NSString *)filename ephemeral:(BOOL)ephemeral {
    self = [super init];
    
    if(self) {
        _filename = filename;
        _ephemeral = ephemeral;
    }
    
    return self;
}

@end
