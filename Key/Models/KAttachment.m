//
//  KAttachment.m
//  Key
//
//  Created by Brendan Farmer on 4/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KAttachment.h"

@implementation KAttachment

- (instancetype)initWithUniqueId:(NSString *)uniqueId media:(NSData *)media type:(NSString *)type hmac:(NSData *)hmac parentUniqueId:(NSString *)parentUniqueId {
    self = [super initWithUniqueId:uniqueId];
    
    if(self) {
        _media = media;
        _type = type;
        _hmac = hmac;
        _parentUniqueId = parentUniqueId;
    }
    return self;
}

@end
