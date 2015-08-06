//
//  KPhoto+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 7/5/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KPhoto+Serialize.h"
#import "NSData+gzip.h"

#define kCoderMedia @"media"
#define kCoderEphemeral @"ephemeral"
#define kCoderParentId @"parentId"

@implementation KPhoto(Serialize)

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithMedia:[[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderMedia] gunzippedData]
                     ephemeral:[aDecoder decodeBoolForKey:kCoderEphemeral]
                      parentId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderParentId]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.media.gzippedData forKey:kCoderMedia];
    [aCoder encodeBool:self.ephemeral forKey:kCoderEphemeral];
    [aCoder encodeObject:self.parentId forKey:kCoderParentId];
}

@end
