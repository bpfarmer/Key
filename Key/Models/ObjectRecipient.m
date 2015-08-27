//
//  ObjectRecipient.m
//  Key
//
//  Created by Brendan Farmer on 8/26/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ObjectRecipient.h"

@implementation ObjectRecipient

- (instancetype)initWithType:(NSString *)type objectId:(NSString *)objectId recipientId:(NSString *)recipientId {
    self = [super init];
    
    if(self) {
        _type        = type;
        _objectId    = objectId;
        _recipientId = recipientId;
    }
    
    return self;
}

@end