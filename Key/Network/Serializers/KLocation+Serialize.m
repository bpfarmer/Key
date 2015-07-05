//
//  KLocation+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 7/5/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KLocation+Serialize.h"

#define kCoderLocation @"location"
#define kCoderUserUniqueId @"userUniqueId"

@implementation KLocation(Serialize)

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithUserUniqueId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderUserUniqueId] location:[aDecoder decodeObjectOfClass:[CLLocation class] forKey:kCoderLocation]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.userUniqueId forKey:kCoderUserUniqueId];
    [aCoder encodeObject:self.location forKey:kCoderLocation];
}

@end
