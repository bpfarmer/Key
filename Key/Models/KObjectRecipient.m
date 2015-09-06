//
//  KObjectRecipient.m
//  Key
//
//  Created by Brendan Farmer on 8/26/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KObjectRecipient.h"

@implementation KObjectRecipient

- (instancetype)initWithObjectId:(NSString *)objectId recipientId:(NSString *)recipientId {
    self = [super init];
    
    if(self) {
        _objectId    = objectId;
        _recipientId = recipientId;
    }
    
    return self;
}

@end
