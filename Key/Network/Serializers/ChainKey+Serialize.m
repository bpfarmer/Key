//
//  ChainKey+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 3/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "ChainKey+Serialize.h"

#define kCoderKeyData @"keyData"
#define kCoderIndex @"index"

@implementation ChainKey(Serialize)

+ (BOOL)supportsSecureCoding{
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    return [self initWithData:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderKeyData]
                        index:[aDecoder decodeIntForKey:kCoderIndex]];
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.keyData forKey:kCoderKeyData];
    [aCoder encodeInt:self.index forKey:kCoderIndex];
}

@end
