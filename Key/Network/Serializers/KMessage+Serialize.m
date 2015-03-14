//
//  KMessage+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 3/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KMessage+Serialize.h"

@implementation KMessage(Serialize)

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.authorId   = [decoder decodeObjectForKey:@"authorId"];
        self.threadId   = [decoder decodeObjectForKey:@"threadId"];
        self.body       = [decoder decodeObjectForKey:@"body"];
        self.createdAt  = [decoder decodeObjectForKey:@"createdAt"];
        
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.authorId forKey:@"authorId"];
    [encoder encodeObject:self.threadId forKey:@"threadId"];
    [encoder encodeObject:self.body forKey:@"body"];
    [encoder encodeObject:self.createdAt forKey:@"createdAt"];
}


@end
