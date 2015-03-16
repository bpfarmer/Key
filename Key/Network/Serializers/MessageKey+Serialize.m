//
//  MessageKey+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 3/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "MessageKey+Serialize.h"

#define kCoderCipherKey @"cipherKey"
#define kCoderMacKey @"macKey"
#define kCoderIv @"iv"
#define kCoderIndex @"index"

@implementation MessageKey(Serialize)

+ (BOOL)supportsSecureCoding{
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    NSNumber *number = (NSNumber *)[aDecoder decodeObjectOfClass:[NSNumber class] forKey:kCoderIndex];
    return [self initWithCipherKey:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderCipherKey]
                            macKey:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderMacKey]
                                iv:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderIv]
                             index:[number intValue]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.cipherKey forKey:kCoderCipherKey];
    [aCoder encodeObject:self.macKey forKey:kCoderMacKey];
    [aCoder encodeObject:self.iv forKey:kCoderIv];
    NSNumber *index = [NSNumber numberWithInt:self.index];
    [aCoder encodeObject:index forKey:kCoderIndex];
}

@end
