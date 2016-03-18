//
//  KLocation+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 7/5/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KLocation+Serialize.h"

#define kCoderLocation @"location"
#define kCoderAuthorId @"authorId"
#define kCoderParentId @"parentId"
#define kCoderAddress @"address"
#define kCoderUniqueId @"uniqueId"

@implementation KLocation(Serialize)

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithUniqueId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderUniqueId]
                         authorId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderAuthorId]
                         location:[aDecoder decodeObjectOfClass:[CLLocation class] forKey:kCoderLocation]
                         parentId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderParentId]
                          address:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderAddress]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.uniqueId forKey:kCoderUniqueId];
    [aCoder encodeObject:self.authorId forKey:kCoderAuthorId];
    [aCoder encodeObject:self.location forKey:kCoderLocation];
    [aCoder encodeObject:self.parentId forKey:kCoderParentId];
    [aCoder encodeObject:self.address forKey:kCoderAddress];
}

@end
