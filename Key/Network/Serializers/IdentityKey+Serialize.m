//
//  IdentityKey+Serialize.m
//  Key
//
//  Created by Brendan Farmer on 3/14/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "IdentityKey+Serialize.h"
#import <25519/Curve25519.h>
#import <25519/Ed25519.h>

#define kCoderUniqueId @"uniqueId"
#define kCoderKeyPair  @"keyPair"
#define kCoderPublicKey @"publicKey"
#define kCoderUserId @"userId"

@implementation IdentityKey(Serialize)

+ (BOOL)supportsSecureCoding{
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    return [self initWithUniqueId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderUniqueId]
                           userId:[aDecoder decodeObjectOfClass:[NSString class] forKey:kCoderUserId]
                        publicKey:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderPublicKey]
                          keyPair:[aDecoder decodeObjectOfClass:[ECKeyPair class] forKey:kCoderKeyPair]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.uniqueId forKey:kCoderUniqueId];
    [aCoder encodeObject:self.keyPair forKey:kCoderKeyPair];
    [aCoder encodeObject:self.publicKey forKey:kCoderPublicKey];
    [aCoder encodeObject:self.userId forKey:kCoderUserId];
}

@end
