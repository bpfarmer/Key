//
//  KAttachment+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 4/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "KAttachment+Serialize.h"

@implementation KAttachment (Serialize)

#define kCoderUniqueId @"uniqueId"
#define kCoderMedia @"media"
#define kCoderHmac @"hmac"
#define kCoderType @"type"
#define kCoderParentUniqueId @"parentUniqueId"

+ (BOOL)supportsSecureCoding {
    return YES;
}

/*
- (id)initWithCoder:(NSCoder *)decoder {
    
    return [self initWithUniqueId:[decoder decodeObjectOfClass:[NSString class] forKey:kCoderUniqueId]
                            media:[decoder decodeObjectOfClass:[NSData class] forKey:kCoderMedia]
                             type:[decoder decodeObjectOfClass:[NSString class] forKey:kCoderType]
                             hmac:[decoder decodeObjectOfClass:[NSData class] forKey:kCoderType]
                   parentUniqueId:[decoder decodeObjectOfClass:[NSString class] forKey:kCoderParentUniqueId]];
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.uniqueId forKey:kCoderUniqueId];
    [encoder encodeObject:self.media forKey:kCoderMedia];
    [encoder encodeObject:self.hmac forKey:kCoderHmac];
    [encoder encodeObject:self.type forKey:kCoderType];
    [encoder encodeObject:self.parentUniqueId forKey:kCoderParentUniqueId];
}
*/
@end
