//
//  SessionState+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 3/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "SessionState+Serialize.h"
#import "MessageKey.h"

#define kCoderMessageKey @"messageKey"
#define kCoderSenderRatchetKey @"senderRatchetKey"
#define kCoderIndex @"index"

@implementation SessionState(Serialize)

+ (BOOL)supportsSecureCoding{
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    NSNumber *number = (NSNumber *)[aDecoder decodeObjectOfClass:[NSNumber class] forKey:kCoderIndex];
    return [self initWithMessageKey:[aDecoder decodeObjectOfClass:[MessageKey class] forKey:kCoderMessageKey]
                   senderRatchetKey:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderSenderRatchetKey]
                              index:[number intValue]];
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.messageKey forKey:kCoderMessageKey];
    [aCoder encodeObject:self.senderRatchetKey forKey:kCoderSenderRatchetKey];
    NSNumber *index = [NSNumber numberWithInt:self.index];
    [aCoder encodeObject:index forKey:kCoderIndex];
    
}

@end
