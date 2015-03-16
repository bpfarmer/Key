//
//  RootKey+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 3/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "RootKey+Serialize.h"

#define kCoderKeyData @"keyData"

@implementation RootKey(Serialize)

+ (BOOL)supportsSecureCoding{
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    return [self initWithData:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderKeyData]];
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.keyData forKey:kCoderKeyData];
}
@end
