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
#define kCoderSessionId @"sessionId"

@implementation SessionState(Serialize)

+ (BOOL)supportsSecureCoding{
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    return [self initWithMessageKey:[aDecoder decodeObjectOfClass:[MessageKey class] forKey:kCoderMessageKey]
                   senderRatchetKey:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderSenderRatchetKey]
                       messageIndex:[aDecoder decodeObjectOfClass:[NSNumber class] forKey:kCoderIndex]
                          sessionId:[aDecoder decodeObjectOfClass:[NSNumber class] forKey:kCoderSessionId]];
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.messageKey forKey:kCoderMessageKey];
    [aCoder encodeObject:self.senderRatchetKey forKey:kCoderSenderRatchetKey];
    [aCoder encodeObject:self.messageIndex forKey:kCoderIndex];
    [aCoder encodeObject:self.sessionId forKey:kCoderSessionId];
}

+ (BOOL)hasUniqueId {
    return NO;
}

@end
