//
//  KPhoto+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 7/5/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KPhoto+Serialize.h"

#define kCoderMedia @"media"
#define kCoderEphemeral @"ephemeral"

@implementation KPhoto(Serialize)

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithMedia:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderMedia]
                     ephemeral:[aDecoder decodeBoolForKey:kCoderEphemeral]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.media forKey:kCoderMedia];
    [aCoder encodeBool:self.ephemeral forKey:kCoderEphemeral];
}

@end
