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
#define kCoderUniqueId @"uniqueId"

@implementation KPhoto(Serialize)

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithUniqueId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderUniqueId]
                            media:[[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderMedia] gunzippedData]
                        ephemeral:[aDecoder decodeBoolForKey:kCoderEphemeral]
                         parentId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderParentId]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.uniqueId forKey:kCoderUniqueId];
    [aCoder encodeObject:self.media.gzippedData forKey:kCoderMedia];
    [aCoder encodeBool:self.ephemeral forKey:kCoderEphemeral];
    [aCoder encodeObject:self.parentId forKey:kCoderParentId];
}

@end
