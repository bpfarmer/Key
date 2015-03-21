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
    return [self initWithMessageKey:[aDecoder decodeObjectOfClass:[MessageKey class] forKey:kCoderMessageKey]
                   senderRatchetKey:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderSenderRatchetKey]
                              index:[aDecoder decodeIntForKey:kCoderIndex]];
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.messageKey forKey:kCoderMessageKey];
    [aCoder encodeObject:self.senderRatchetKey forKey:kCoderSenderRatchetKey];
    [aCoder encodeInt:self.index forKey:kCoderIndex];
    
}

@end
